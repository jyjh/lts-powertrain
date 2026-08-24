function tests = PowertrainSmokeTest
tests = functiontests(localfunctions);
end

function testDefaultMapLoadsWithoutArguments(testCase)
% Exercises the package-folder-relative resolution of the default EMRAX
% map (data/powertrain inside this repository) — the path contract the
% main repository relies on when cfg.powertrain.matFile is ''.
pt = lts.components.Powertrain.EMRAX228Powertrain();
verifyTrue(testCase, isfinite(pt.maxEngineTorque));
verifyGreaterThan(testCase, pt.maxEngineTorque, 0);
end

function testComputeDriveTorqueFullThrottleIsPositive(testCase)
pt = lts.components.Powertrain.EMRAX228Powertrain();
pt = pt.setDrivenWheelRadius(0.24);
tq = pt.computeDriveTorque(10, 1);
verifyTrue(testCase, isfinite(tq));
verifyGreaterThan(testCase, tq, 0);
end

function testZeroThrottleDeliversNoTorque(testCase)
pt = lts.components.Powertrain.EMRAX228Powertrain();
pt = pt.setDrivenWheelRadius(0.24);
verifyEqual(testCase, pt.computeDriveTorque(10, 0), 0, 'AbsTol', 1e-12);
end

function testExplicitMapPathIsUsedDirectly(testCase)
% An existing absolute/relative path must bypass the default resolution.
here = fileparts(mfilename('fullpath'));
mapFile = fullfile(here, '..', 'data', 'powertrain', ...
    'EMRAX228CC Single_4.5.mat');
pt = lts.components.Powertrain.EMRAX228Powertrain(mapFile);
verifyTrue(testCase, isfinite(pt.maxEngineTorque));
end
