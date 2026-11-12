function data = generateMicroscopyData(outputFile)
    %generateMicroscopyData - Create reproducible two-channel cell images
    %   DATA = generateMicroscopyData() creates four synthetic image fields
    %   with independent ground-truth masks and reporter signal values.
    %
    %   DATA = generateMicroscopyData(outputFile) also saves DATA to a
    %   MAT-file. Images are 12-bit camera counts stored as UINT16.
    %
    %   See also loadMicroscopyData, analyzeMicroscopyField

    arguments
        outputFile {mustBeTextScalar} = ""
    end

    stream = RandStream("mt19937ar", Seed=2026);
    [x, y] = meshgrid(1:512, 1:384);
    fieldNames = ["Sparse", "Dense"];
    conditions = ["Basal", "Induced"];
    fields = cell(4, 1);
    for fieldIndex = 1:2
        [labels, cellCount] = createLabels(x, y, fieldIndex, stream);
        debris = (x-240).^2 + (y-365).^2 < 6 | ...
            (x-330).^2 + (y-360).^2 < 5;
        foreground = labels > 0 | debris;
        reference = 110 + 30*x/512 + 760*imgaussfilt(double(foreground), 0.7);
        reference = reference + 12*randn(stream, size(x));
        reference = uint16(max(0, reference));
        borderIds = unique([labels(1, :), labels(end, :), ...
            labels(:, 1)', labels(:, end)']);
        for conditionIndex = 1:2
            signal = (120 + 30*(conditionIndex-1))* ...
                exp(0.28*randn(stream, cellCount, 1));
            if conditionIndex == 2
                signal = signal*5;
                signal(1:2) = [5300; 5700];
            end
            cleanReporter = zeros(size(x));
            for cellIndex = 1:cellCount
                cleanReporter(labels == cellIndex) = signal(cellIndex);
            end
            reporter = 65 + 10*x/512 + imgaussfilt(cleanReporter, 0.7) + ...
                8*randn(stream, size(x));
            reporter = uint16(min(4095, max(0, reporter)));
            truth = table((1:cellCount)', signal, ...
                ismember((1:cellCount)', double(borderIds)), signal > 4095, ...
                VariableNames=["CellID", "ReporterSignalADU", ...
                "TouchesBorder", "Saturated"]);
            fields{2*(fieldIndex-1)+conditionIndex} = struct( ...
                Field=fieldNames(fieldIndex), Condition=conditions(conditionIndex), ...
                ReferenceImage=reference, ReporterImage=reporter, ...
                TruthLabels=labels, TruthMeasurements=truth);
        end
    end
    data = struct(Fields=[fields{:}], Seed=2026, PixelSizeMicrometers=0.35, ...
        SaturationADU=4095, SchemaVersion=1, ...
        Description="Synthetic educational images; not experimental observations.");
    if strlength(string(outputFile)) > 0
        save(outputFile, "data");
    end
end

function [labels, cellCount] = createLabels(x, y, fieldIndex, stream)
    labels = zeros(size(x), "uint16");
    bestDistance = inf(size(x));
    cellCount = 0;
    for row = 1:6
        for column = 1:6
            baseX = 44 + (column-1)*82;
            baseY = 42 + (row-1)*57;
            for member = 1:fieldIndex
                cellCount = cellCount + 1;
                centerX = baseX + (member-1.5)*22*(fieldIndex == 2);
                centerY = baseY + 2*randn(stream);
                radiusX = 13.5 + 0.7*rand(stream);
                radiusY = 12 + rand(stream);
                distance = ((x-centerX)/radiusX).^2 + ((y-centerY)/radiusY).^2;
                selected = distance <= 1 & distance < bestDistance;
                labels(selected) = cellCount;
                bestDistance(selected) = distance(selected);
            end
        end
    end
    borderCenters = [2 180; 512 220];
    for index = 1:2
        cellCount = cellCount + 1;
        selected = ((x-borderCenters(index, 1))/14).^2 + ...
            ((y-borderCenters(index, 2))/12).^2 <= 1;
        labels(selected) = cellCount;
    end
end
