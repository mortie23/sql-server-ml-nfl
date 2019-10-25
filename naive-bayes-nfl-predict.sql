-- Author:  Christopher Mortimer
-- Date:    2019-10-25
-- Desc:    Predict number of touchdowns in an NFL game using the trained model
-- Notes:   Based on MS tutorial
--          https://docs.microsoft.com/en-us/sql/advanced-analytics/tutorials/quickstart-python-train-score-model?view=sql-server-ver15

USE PRD_SI_NFL
GO

DROP PROCEDURE predict_touchdowns
GO

CREATE PROCEDURE predict_touchdowns (@model VARCHAR(100))
AS
BEGIN
    DECLARE @nb_model VARBINARY(max) = (
            SELECT  model
            FROM    dbo.nfl_models
            WHERE   model_name = @model
    );

    EXECUTE sp_execute_external_script 
        @language = N'Python'
        , @script = N'
        import pickle
        nflmodel = pickle.loads(nb_model)
        pred_touchdowns = nflmodel.predict(nfl_data[["TOTAL_FIRST_DOWNS", "TOTAL_YARDS", "INTERCEPTIONS", "PUNTS"]])
        nfl_data["Predicted_TOTAL_TD"] = pred_touchdowns
        OutputDataSet = nfl_data[["GAME_ID", "TEAM_ID", "TOTAL_TD","Predicted_TOTAL_TD"]] 
        print(OutputDataSet)
        '
        , @input_data_1 = N'select [GAME_ID], [TEAM_ID], [TOTAL_FIRST_DOWNS], [TOTAL_YARDS], [INTERCEPTIONS], [PUNTS], [TOTAL_TD] from [dbo].[GAME_STATS]'
        , @input_data_1_name = N'nfl_data'
        , @params = N'@nb_model varbinary(max)'
        , @nb_model = @nb_model
        WITH RESULT SETS(
            (
                "GAME_ID" INT
                , "TEAM_ID" INT
                , "TOTAL_TD" INT
                , "Predicted_TOTAL_TD" INT
            )
        );
END;
GO

EXECUTE predict_touchdowns 'Naive Bayes';
GO