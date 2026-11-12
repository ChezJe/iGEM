%[text] # Which fluorescent biosensor can quantify this sample?
%[text] A fluorescence measurement becomes a concentration only through a calibration. Two synthetic sensors illustrate why a bright signal can carry little concentration information near a plateau.
%[text] The concentrations are in micromolar (µM), and fluorescence is in relative fluorescence units (RFU). All observations are synthetic; they are not measurements of a particular biological sensor.
demoRoot = setupBiosensor;
bundle = biosensor.loadData;
%%
%[text] ## Inspect the replicated standards
%[text] Each sensor has six independent observations at each concentration, including blank controls. The unknown sample has a separate set of fluorescence measurements for each sensor.
calibration = readtable(fullfile(demoRoot,"data","calibration.csv"),TextType="string");
summary = groupsummary(calibration,["Sensor","Concentration_uM"],["mean","std"],"Fluorescence_RFU");
summary(1:6,:)
%%
%[text] ## Fit a saturating response
%[text] The positive-parameter Hill model is $ F(c)=B+A\\frac{c^h}{K^h+c^h} $. The baseline is $ B $, the response amplitude is $ A $, and $ K $ is EC50. EC50 is not a detection limit.
%[text] The fit minimizes weighted residuals. Replicate variation sets the weights, with a small noise floor. The app uses bootstrap fits generated with this same function; they are bundled so the live comparison stays quick.
sensorA = biosensor.fitCalibration(calibration(calibration.Sensor == "A",:),0);
sensorB = biosensor.fitCalibration(calibration(calibration.Sensor == "B",:),0);
parameters = array2table([sensorA.Parameters;sensorB.Parameters],VariableNames=["Baseline_RFU","Amplitude_RFU","EC50_uM","HillCoefficient"],RowNames=["Sensor A","Sensor B"]);
disp(parameters)
%%
%[text] ## Invert each sensor's measurement
%[text] Change `sampleID` to `"U2"` or `"U3"` to explore a different prepared unknown. Both sensors measure the same underlying concentration, but their fluorescence observations differ.
sampleID = "U1";
results = biosensor.inferConcentration(bundle,sampleID);
results(:,["SampleID","Sensor","MeanFluorescence_RFU","Estimate_uM","Lower95_uM","Upper95_uM","Status"])
biosensor.plotCalibration(bundle,sampleID);
%%
%[text] ## Preserve uncertainty near the limits
%[text] Concentration intervals combine within-standard bootstrap calibration fits with resampled unknown replicates. Inversions above a fitted plateau remain infinite; they are not removed to produce a narrower interval. Signals below the fitted baseline are lower-censored at zero.
%[text] The 95% amplitude threshold marks a near-saturation caution for this demonstration. It is not a validated assay quantification limit. Check the interval and calibrated range before using an estimate.
weakSignal = biosensor.inferConcentration(bundle,"U3");
weakSignal(:,["Sensor","Estimate_uM","Lower95_uM","Upper95_uM","Status"])
%%
%[text] ## Compare with known synthetic truth
%[text] The hidden concentrations exist only because these observations were generated for a demonstration. They let us check the analysis; they are not used by the calibration or inverse-estimation functions.
comparison = join(results,bundle.Truth,Keys="SampleID");
comparison(:,["Sensor","Estimate_uM","TrueConcentration_uM","Quantifiable","Status"])
%[text] To regenerate the data and bootstrap fits, run `biosensor.generateData` from the demo folder. The random streams are local and repeatable. Use the app's Export CSV action to save the displayed result table, including its uncertainty and status.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
