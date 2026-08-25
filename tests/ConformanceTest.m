function tests = ConformanceTest
% CONFORMANCETEST Pin the contract between this repository and the main
% lts repository (contract items 1-3 of the repository split; see the
% Contracts page of the main repository's documentation).
%
%  1. cfg schema — lts.components.Powertrain.validateConfig accepts the
%     canonical cfg.powertrain and rejects bad input with typed errors.
%  2. Interface — EMRAX228Powertrain subclasses PowertrainComponent;
%     the differential classes subclass DifferentialComponent.
%  3. Telemetry producer fields — the PowertrainState property names
%     below are read directly by the Simulator for the motor/pack
%     telemetry channels (motorRPM, motorTorque, wheelTorque, ...).
%     Renaming any of them is a contract change: update this test and
%     the Contracts page in the same PR, then coordinate the
%     main-repository change (see "Changing the contract" there).
tests = functiontests(localfunctions);
end

function cfg = canonicalConfig()
% Mirrors the baseline cfg.powertrain from the main repository's
% VehicleConfig.
cfg = struct( ...
    'matFile', '', ...
    'finalDriveRatio', NaN, ...
    'efficiency', 0.92, ...
    'efficiencyRpm', [], ...
    'efficiencyValues', [], ...
    'regenEfficiency', NaN, ...
    'deliveredTorqueDrivetrainEfficiency', NaN, ...
    'motorRotorInertia', 0.07, ...
    'regenEnabled', false, ...
    'motoringDragTorque', 0, ...
    'motoringDragThrottleThreshold', Inf, ...
    'regenTorqueLimitNm', 30, ...
    'regenEnabledSpeedFloor', 1.0, ...
    'throttleDeadband', 0, ...
    'throttleMapInput', [0.00 0.15 0.35 0.60 0.80 1.00], ...
    'throttleMapOutput', [0.00 0.02 0.10 0.28 0.58 1.00], ...
    'differential', struct('type', 'open'));
end

%% ---- 1. Config schema --------------------------------------------------

function testValidateConfigAcceptsCanonicalConfig(testCase)
verifyTrue(testCase, ...
    lts.components.Powertrain.validateConfig(canonicalConfig()));
end

function testValidateConfigRejectsMissingField(testCase)
cfg = canonicalConfig();
cfg = rmfield(cfg, 'efficiency');
verifyError(testCase, ...
    @() lts.components.Powertrain.validateConfig(cfg), ...
    'lts_powertrain_validateConfig:MissingField');
end

function testValidateConfigRejectsBadEfficiency(testCase)
cfg = canonicalConfig();
cfg.efficiency = 1.4;
verifyError(testCase, ...
    @() lts.components.Powertrain.validateConfig(cfg), ...
    'lts_powertrain_validateConfig:OutOfRange');
end

function testValidateConfigRejectsUnknownDifferential(testCase)
cfg = canonicalConfig();
cfg.differential.type = 'torque-vectoring';
verifyError(testCase, ...
    @() lts.components.Powertrain.validateConfig(cfg), ...
    'lts_powertrain_validateConfig:UnknownDifferential');
end

function testValidateConfigRejectsCurveLengthMismatch(testCase)
cfg = canonicalConfig();
cfg.efficiencyRpm = [1000 4000];
cfg.efficiencyValues = [0.9];
verifyError(testCase, ...
    @() lts.components.Powertrain.validateConfig(cfg), ...
    'lts_powertrain_validateConfig:InvalidVector');
end

%% ---- 2. Interface (contract item 1) -------------------------------------

function testEMRAXSubclassesPowertrainComponent(testCase)
mc = meta.class.fromName( ...
    'lts.components.Powertrain.EMRAX228Powertrain');
supers = {mc.SuperclassList.Name};
verifyTrue(testCase, ...
    any(endsWith(supers, 'PowertrainComponent')), ...
    'EMRAX228Powertrain must subclass PowertrainComponent.');
end

function testDifferentialsSubclassDifferentialComponent(testCase)
classes = {'OpenDifferential', 'LockedDifferential', ...
    'ClutchLSDDifferential', 'DrexlerRampPlateDifferential'};
for i = 1:numel(classes)
    mc = meta.class.fromName( ...
        sprintf('lts.components.Powertrain.%s', classes{i}));
    supers = {mc.SuperclassList.Name};
    verifyTrue(testCase, ...
        any(endsWith(supers, 'DifferentialComponent')), ...
        sprintf('%s must subclass DifferentialComponent.', classes{i}));
end
end

%% ---- 3. Telemetry producer fields (contract item 3) ---------------------

function testPowertrainStatePinsTelemetryFieldNames(testCase)
% Exact property names lts.simulation.Simulator reads from
% powertrain.state for the motor/pack channels.
mc = meta.class.fromName('lts.components.Powertrain.PowertrainState');
props = {mc.PropertyList.Name};
required = {'motorRPM', 'motorTorque', 'requestedMotorTorque', ...
    'motorTorquePowerLimitNm', 'motorTorquePowerLimitActive', ...
    'wheelTorque', 'packVoltageV', 'packCurrentA', 'packPowerW', ...
    'drivenWheelRPM', 'rpmLimitActive'};
for i = 1:numel(required)
    verifyTrue(testCase, ismember(required{i}, props), ...
        sprintf('PowertrainState must keep property %s.', required{i}));
end
end

function testDefaultMapResolvesPackageRelative(testCase)
% matFile = '' must keep loading the EMRAX map from this repository's
% data/powertrain/ — the path contract behind cfg.powertrain.matFile.
pt = lts.components.Powertrain.EMRAX228Powertrain();
verifyTrue(testCase, isfinite(pt.maxEngineTorque));
verifyGreaterThan(testCase, pt.maxEngineTorque, 0);
end
