function response = hillResponse(parameters, concentration)
    %hillResponse - Evaluate a positive-parameter Hill calibration
    %   RESPONSE = hillResponse(PARAMETERS,CONCENTRATION) evaluates rows
    %   [baseline, amplitude, EC50, Hill coefficient] at nonnegative
    %   concentrations. Rows of RESPONSE correspond to parameter sets.
    %
    %   See also biosensor.fitCalibration, biosensor.inferConcentration
    arguments
        parameters (:,4) {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive}
        concentration (1,:) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNonnegative}
    end
    powered = (concentration./parameters(:,3)).^parameters(:,4);
    response = parameters(:,1) + parameters(:,2).*powered./(1 + powered);
end
