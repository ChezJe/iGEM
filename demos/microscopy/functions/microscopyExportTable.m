function rows = microscopyExportTable(result, field, condition)
    %microscopyExportTable - Add acquisition and analysis settings to results
    %   ROWS = microscopyExportTable(RESULT,FIELD,CONDITION) combines the
    %   measured cells and settings in a table suitable for WRITETABLE.
    %
    %   See also analyzeMicroscopyField, writetable

    arguments
        result (1,1) struct
        field {mustBeTextScalar}
        condition {mustBeTextScalar}
    end

    rows = result.Cells;
    count = height(rows);
    rows.Field = repmat(string(field), count, 1);
    rows.Condition = repmat(string(condition), count, 1);
    rows.SplitTouching = repmat(result.Settings.SplitTouching, count, 1);
    rows.PixelSizeMicrometers = repmat(result.Settings.PixelSizeMicrometers, count, 1);
    rows.BackgroundADU = repmat(result.Summary.BackgroundADU, count, 1);
    rows.SaturationADU = repmat(result.Settings.SaturationADU, count, 1);
    rows.MinimumAreaPixels = repmat(result.Settings.MinimumAreaPixels, count, 1);
    rows.GaussianSigmaPixels = repmat(result.Settings.GaussianSigmaPixels, count, 1);
    rows.WatershedDepthPixels = repmat(result.Settings.WatershedDepthPixels, count, 1);
end
