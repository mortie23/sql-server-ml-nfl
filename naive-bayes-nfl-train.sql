-- Author:  Christopher Mortimer
-- Date:    2019-10-25
-- Desc:    Train a Niave Bayes model to predict number of touchdowns in an NFL game
-- Notes:   Based on MS tutorial
--          https://docs.microsoft.com/en-us/sql/advanced-analytics/tutorials/quickstart-python-train-score-model?view=sql-server-ver15

USE PRD_SI_NFL
GO

drop table if exists dbo.nfl_models;
GO

create table dbo.nfl_models (
	model_name varchar(50)
	, model varbinary(max)
)
go

drop procedure generate_nfl_model
go

CREATE PROCEDURE generate_nfl_model (@trained_model VARBINARY(max) OUTPUT)
AS
BEGIN
EXECUTE sp_execute_external_script @language = N'Python'
, @script = N'
import pickle
from sklearn.naive_bayes import GaussianNB
GNB = GaussianNB()
trained_model = pickle.dumps(GNB.fit(game_stats_data[["TOTAL_FIRST_DOWNS", "TOTAL_YARDS", "INTERCEPTIONS", "PUNTS"]], game_stats_data[["TOTAL_TD"]].values.ravel()))
'
, @input_data_1 = N'select [TOTAL_FIRST_DOWNS], [TOTAL_YARDS], [INTERCEPTIONS], [PUNTS], [TOTAL_TD] from [dbo].[GAME_STATS]'
, @input_data_1_name = N'game_stats_data'
, @params = N'@trained_model varbinary(max) OUTPUT'
, @trained_model = @trained_model OUTPUT;
END;
GO

DECLARE @model varbinary(max);
DECLARE @new_model_name varchar(50)
SET @new_model_name = 'Naive Bayes'
EXECUTE generate_nfl_model @model OUTPUT;
DELETE dbo.[nfl_models] WHERE model_name = @new_model_name;
INSERT INTO dbo.[nfl_models] (model_name, model) 
	values(@new_model_name, @model);
GO

select *
from	dbo.[nfl_models]
