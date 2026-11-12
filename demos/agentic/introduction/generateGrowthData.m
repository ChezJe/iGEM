function measurements = generateGrowthData(outputFolder)
%generateGrowthData - Generate reproducible synthetic plate-reader data
%   T = generateGrowthData(FOLDER) writes measurements and generation truth
%   to FOLDER. Times are hours and OD600 is dimensionless absorbance.
%
%   See also readtable, analyzeGrowth
arguments
    outputFolder (1,1) string = fullfile(fileparts(mfilename("fullpath")), "data")
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
stream = RandStream("mt19937ar", Seed=2026);
time = (0:0.125:12)';
constructs = ["Reference", "Construct A", "Construct B"];
rates = [0.75, 0.62, 0.45];
replicateFactors = [0.96, 1, 1.04];
nTimes = numel(time);
rows = cell(12,1);
truth = zeros(9,1);
wellNames = strings(9,1);
for constructIndex = 1:3
    for replicate = 1:3
        index = (constructIndex - 1)*3 + replicate;
        rate = rates(constructIndex)*replicateFactors(replicate);
        lag = 1.2 + 0.1*(replicate - 2);
        transitionTime = lag + log(0.38/0.02)/rate;
        density = 0.02*exp(rate*max(0,time - lag));
        late = time > transitionTime;
        % Join exponential growth smoothly to a stationary phase.
        density(late) = 1.2 - (1.2 - 0.38)*exp( ...
            -0.38*rate/(1.2 - 0.38)*(time(late) - transitionTime));
        blank = 0.06 + 0.003*time/12;
        measured = blank + density + (0.0005 + 0.006*density).*randn(stream,nTimes,1);
        well = "A" + compose("%02d",index);
        rows{index} = table(time,repmat(well,nTimes,1), ...
            repmat(constructs(constructIndex),nTimes,1), ...
            repmat(replicate,nTimes,1),measured,false(nTimes,1), ...
            VariableNames=["Time_h","Well","Construct","Replicate","OD600","IsBlank"]);
        truth(index) = rate;
        wellNames(index) = well;
    end
end
for replicate = 1:3
    blank = 0.06 + 0.003*time/12 + 0.0004*randn(stream,nTimes,1);
    rows{9 + replicate} = table(time,repmat("B" + compose("%02d",replicate),nTimes,1), ...
        repmat("Blank",nTimes,1),repmat(replicate,nTimes,1),blank,true(nTimes,1), ...
        VariableNames=["Time_h","Well","Construct","Replicate","OD600","IsBlank"]);
end
measurements = vertcat(rows{:});
measurements.Properties.VariableUnits = ["h","","","",""," "];
writetable(measurements,fullfile(outputFolder,"plateReader.csv"));
generationTruth = table(wellNames,truth,VariableNames=["Well","GrowthRate_per_h"]);
writetable(generationTruth,fullfile(outputFolder,"generationTruth.csv"));
end
