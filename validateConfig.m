function ok = validateConfig(cfg)
% VALIDATECONFIG Validate the cfg.powertrain struct consumed by this package.
%   ok = lts.components.Powertrain.validateConfig(cfg)
%
% Contract item 2 of the repository split (see the Contracts page of the
% main repository's documentation): each component repository owns the
% schema of its cfg sub-struct and validates it at the build boundary.
%
% Fields (SI unless noted):
%   matFile        ['' | path] EMRAX map; '' = the default map in this
%                  repository's data/powertrain/
%   efficiency     [0-1] motoring drivetrain efficiency (> 0)
%   differential.type 'open' | 'locked' | 'lsd' | 'clutchlsd' |
%                  'drexler' | 'drexlerrampplate' | 'rampplate'
%   Optional (validated only when present):
%     finalDriveRatio   [-] NaN = map value; else > 0
%     motorRotorInertia [kg*m^2] >= 0
%     efficiencyRpm / efficiencyValues  equal-length numeric vectors
%     regenEfficiency   [0-1] or NaN
%     deliveredTorqueDrivetrainEfficiency [0-1] or NaN
%     regenEnabled (logical), motoringDragTorque (>= 0),
%     motoringDragThrottleThreshold [0-1] or Inf,
%     regenTorqueLimitNm (> 0), regenEnabledSpeedFloor (>= 0),
%     throttleDeadband [0-1],
%     throttleMapInput / throttleMapOutput equal-length vectors
%
% Returns logical true on success; otherwise throws with identifier
% lts_powertrain_validateConfig:<Case> (MissingField | InvalidScalar |
% OutOfRange | InvalidVector | UnknownDifferential).

required = {'matFile', 'efficiency', 'differential'};
for i = 1:numel(required)
    if ~isfield(cfg, required{i})
        error('lts_powertrain_validateConfig:MissingField', ...
            'cfg.powertrain.%s is required.', required{i});
    end
end

if ~(ischar(cfg.matFile) || isstring(cfg.matFile))
    error('lts_powertrain_validateConfig:InvalidScalar', ...
        'cfg.powertrain.matFile must be a char/string path ("" = default).');
end
if ~isstruct(cfg.differential) || ~isfield(cfg.differential, 'type')
    error('lts_powertrain_validateConfig:MissingField', ...
        'cfg.powertrain.differential.type is required.');
end
knownTypes = {'open', 'locked', 'lsd', 'clutchlsd', ...
    'drexler', 'drexlerrampplate', 'rampplate'};
if ~any(strcmpi(cfg.differential.type, knownTypes))
    error('lts_powertrain_validateConfig:UnknownDifferential', ...
        'Unknown differential type "%s".', cfg.differential.type);
end

localCheckScalar(cfg, 'efficiency');
if cfg.efficiency <= 0 || cfg.efficiency > 1
    error('lts_powertrain_validateConfig:OutOfRange', ...
        'cfg.powertrain.efficiency=%g must be in (0, 1].', cfg.efficiency);
end

scalars = {'motorRotorInertia', 'regenEfficiency', ...
    'deliveredTorqueDrivetrainEfficiency', 'motoringDragTorque', ...
    'motoringDragThrottleThreshold', 'regenTorqueLimitNm', ...
    'regenEnabledSpeedFloor', 'throttleDeadband', 'finalDriveRatio'};
for i = 1:numel(scalars)
    f = scalars{i};
    if ~isfield(cfg, f) || isempty(cfg.(f)) || ...
            (isnumeric(cfg.(f)) && isnan(cfg.(f)))
        continue;  % optional / NaN = use default
    end
    localCheckScalar(cfg, f);
end
if isfield(cfg, 'finalDriveRatio') && isfinite(cfg.finalDriveRatio) ...
        && ~isempty(cfg.finalDriveRatio) && cfg.finalDriveRatio <= 0
    error('lts_powertrain_validateConfig:OutOfRange', ...
        'cfg.powertrain.finalDriveRatio must be NaN (map) or > 0.');
end

if isfield(cfg, 'efficiencyRpm') && ~isempty(cfg.efficiencyRpm)
    if ~isnumeric(cfg.efficiencyRpm) || ~isvector(cfg.efficiencyRpm) ...
            || any(~isfinite(cfg.efficiencyRpm(:)))
        error('lts_powertrain_validateConfig:InvalidVector', ...
            'cfg.powertrain.efficiencyRpm must be a finite numeric vector.');
    end
    if ~isfield(cfg, 'efficiencyValues') || ...
            numel(cfg.efficiencyValues) ~= numel(cfg.efficiencyRpm)
        error('lts_powertrain_validateConfig:InvalidVector', ...
            ['cfg.powertrain.efficiencyValues must be the same length ' ...
            'as efficiencyRpm.']);
    end
end

if isfield(cfg, 'throttleMapInput') && ~isempty(cfg.throttleMapInput)
    if ~isfield(cfg, 'throttleMapOutput') || ...
            numel(cfg.throttleMapOutput) ~= numel(cfg.throttleMapInput)
        error('lts_powertrain_validateConfig:InvalidVector', ...
            ['cfg.powertrain.throttleMapOutput must be the same length ' ...
            'as throttleMapInput.']);
    end
end

ok = true;
end

function localCheckScalar(cfg, name)
value = cfg.(name);
if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ...
        (~isfinite(value) && ~any(isinf(value)))
    error('lts_powertrain_validateConfig:InvalidScalar', ...
        'cfg.powertrain.%s must be a real scalar (got %s).', ...
        name, mat2str(value));
end
end
