function result = analyzeGrowth(measurements)
%analyzeGrowth - Estimate exponential growth independently for each well
%   RESULT = analyzeGrowth(T) subtracts time-matched blank means and fits
%   log OD600 between 0.05 and 0.30 using at least five observations.
%   RESULT contains corrected measurements, well fits, and summaries.
%
%   See also fitlm, groupsummary, loadGrowthData
arguments
    measurements {mustBeA(measurements,"table")}
end
required = ["Time_h","Well","Construct","Replicate","OD600","IsBlank"];
assert(all(ismember(required,string(measurements.Properties.VariableNames))), ...
    "igem:GrowthSchema","Required plate-reader variables are missing.");
assert(isnumeric(measurements.Time_h) && isnumeric(measurements.OD600), ...
    "igem:GrowthType","Time_h and OD600 must contain numeric measurements.");
isBlank = logical(measurements.IsBlank);
validBlank = isBlank & isfinite(measurements.Time_h) & isfinite(measurements.OD600);
assert(any(validBlank),"igem:MissingBlanks","At least one finite blank measurement is required.");
blanks = groupsummary(measurements(validBlank,:),"Time_h","mean","OD600");
cultures = measurements(~isBlank,:);
assert(~isempty(cultures),"igem:MissingCultures","At least one culture well is required.");
assert(all(ismember(cultures.Time_h,blanks.Time_h)),"igem:UnmatchedBlank", ...
    "Every culture time must have a finite blank measurement at the same time.");
blankMeans = renamevars(blanks(:,["Time_h","mean_OD600"]),"mean_OD600","BlankOD600");
cultures = innerjoin(cultures,blankMeans,Keys="Time_h");
cultures = sortrows(cultures,["Well","Time_h"]);
cultures.Well = string(cultures.Well);
cultures.Construct = string(cultures.Construct);
cultures.CorrectedOD600 = cultures.OD600 - cultures.BlankOD600;
cultures.InFit = false(height(cultures),1);
cultures.FittedOD600 = nan(height(cultures),1);
wells = unique(cultures.Well,"stable");
nWells = numel(wells);
fits = table(wells,strings(nWells,1),zeros(nWells,1), ...
    nan(nWells,1),nan(nWells,1),nan(nWells,1),nan(nWells,1), ...
    zeros(nWells,1),nan(nWells,1),strings(nWells,1), ...
    VariableNames=["Well","Construct","Replicate","GrowthRate_per_h", ...
    "Lower95_per_h","Upper95_per_h","DoublingTime_h","FitN","RSquared","Status"]);
for index = 1:nWells
    inWell = cultures.Well == wells(index);
    wellData = cultures(inWell,:);
    assert(numel(unique(wellData.Time_h)) == height(wellData), ...
        "igem:DuplicateTime","Each well must have one observation per time.");
    assert(numel(unique(wellData.Construct)) == 1 && numel(unique(wellData.Replicate)) == 1, ...
        "igem:WellIdentity","Construct and replicate must be consistent within each well.");
    fits.Construct(index) = wellData.Construct(1);
    fits.Replicate(index) = wellData.Replicate(1);
    selected = isfinite(wellData.Time_h) & isfinite(wellData.CorrectedOD600) & ...
        wellData.CorrectedOD600 >= 0.05 & wellData.CorrectedOD600 <= 0.30;
    fits.FitN(index) = nnz(selected);
    if nnz(selected) < 5
        fits.Status(index) = "Insufficient exponential-phase observations";
        continue
    end
    model = fitlm(wellData.Time_h(selected),log(wellData.CorrectedOD600(selected)));
    slope = model.Coefficients.Estimate(2);
    interval = coefCI(model);
    fits.GrowthRate_per_h(index) = slope;
    fits.Lower95_per_h(index) = interval(2,1);
    fits.Upper95_per_h(index) = interval(2,2);
    fits.RSquared(index) = model.Rsquared.Ordinary;
    rows = find(inWell);
    fitRows = rows(selected);
    cultures.InFit(fitRows) = true;
    cultures.FittedOD600(fitRows) = exp(predict(model,wellData.Time_h(selected)));
    if slope <= 0 || interval(2,1) <= 0
        fits.Status(index) = "Positive growth not established";
    else
        fits.DoublingTime_h(index) = log(2)/slope;
        fits.Status(index) = "Estimated";
    end
end
goodFits = fits(fits.Status == "Estimated",:);
summary = groupsummary(goodFits,"Construct",["mean","std"],"GrowthRate_per_h");
result = struct("Measurements",cultures,"BlankMeans",blanks, ...
    "ReplicateFits",fits,"Summary",summary,"FitRange",[0.05,0.30]);
end
