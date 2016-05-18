
#ipython notebook --profile=pyspark /Users/kveeravalli/Desktop/239_proj/sparkhpd/sparkpred.py
from pyspark import SparkContext, SparkConf
import pandas as pd
import numpy as np
from pyspark.mllib.regression import LabeledPoint
from pyspark.mllib.tree import DecisionTree
import sys
import httplib

def run_decision_tree(userid):
	conf = SparkConf().setMaster("local[1]").setAppName("heart-disease-prediction-descision-tree")
	sc   = SparkContext(conf=conf)

	print "Running Spark Version %s" % (sc.version)


	# https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/processed.cleveland.data
	path = "/home/raju/Documents/hdp_proj"
	heartdf_tr = pd.read_csv(path+"processed.cleveland.data.csv",header=None)
	heartdf_test = pd.read_csv(path+"testdata.csv",header=None)
	print "Original training Dataset (Rows:Colums): "
	print heartdf_tr.shape
	print heartdf_test.shaperead_csvread_csvread_csv

	print "Categories of Diagnosis of heart disease (angiographic disease status) that we are predicting"
	print "-- Value 0: < 50% diameter narrowing"
	print "-- Value 1: > 50% diameter narrowing "
	print heartdf_tr.ix[:,13].unique() #Column containing the Diagnosis of heart disease
	print heartdf_test.ix[:,13].unique() #Column containing the Diagnosis of heart disease

	newheartdf = pd.concat([heartdf_tr.ix[:,13], heartdf_tr.ix[:,0:12]],axis=1, join_axes=[heartdf_tr.index])
	newheartdf_test = pd.concat([heartdf_test.ix[:,13], heartdf_test.ix[:,0:12]],axis=1, join_axes=[heartdf_test.index])
	newheartdf.replace('?', np.nan, inplace=True) # Replace ? values
	newheartdf_test.replace('?', np.nan, inplace=True) # Replace ? values

	print "After dropping rows with anyone empty value (Rows:Columns): "
	ndf2 = newheartdf.dropna()
	ndf_test = newheartdf_test.dropna()

	ndf2.to_csv(path+"new-heart-disease-cleaveland.txt",sep=",",index=False,header=None,na_rep=np.nan)
	ndf_test.to_csv(path+"new-heart-disease-cleaveland-test.txt",sep=",",index=False,header=None,na_rep=np.nan)

	print ndf2.shape
	print ndf_test.shape
	print ndf2.ix[:5,:]
	print ndf_test.ix[:5,:]

	print "Create a Labeled point which is a local vector, associated with a label/response"

	points = sc.textFile(path+'new-heart-disease-cleaveland.txt')
	points_test = sc.textFile(path+'new-heart-disease-cleaveland-test.txt')

	print "###############################Something"
	parsed_data = points.map(parsePoint)
	parsed_data_test = points_test.map(parsePoint)

	print 'After parsing, number of training lines: %s' %parsed_data.take(5)  #parsed_data.count()
	print 'After parsing, number of test data lines: %s' %parsed_data_test.take(5)  #parsed_data.count()


	#####Perform Classification using a Decision Tree#####
	# Split the data into training and test sets (30% held out for testing)
	(trainingData, trainingData1) = parsed_data.randomSplit([1,0])
	(testData , testData1) = parsed_data_test.randomSplit([1,0])
	# Train a DecisionTree model.
	#  Empty categoricalFeaturesInfo indicates all features are continuous. 
	print "+++++++++++++++++++++++++++++++++ Perform Classification using a Decision Tree +++++++++++++++++++++++++++++++++"
	model = DecisionTree.trainClassifier(trainingData, numClasses=5, categoricalFeaturesInfo={}, impurity='gini', maxDepth=4, maxBins=32)

	predictions = model.predict(testData.map(lambda x: x.features))
	labelsAndPredictions = testData.map(lambda lp: lp.label).zip(predictions)
	testErr = labelsAndPredictions.filter(lambda (v, p): v != p).count() / float(testData.count())
	print('Test Error = ' + str(testErr))
	print('=================== Learned classification tree model ====================')
	print(model.toDebugString())


	print "+++++++++++++++++++++++++++++++++ Perform Regression using a Decision Tree +++++++++++++++++++++++++++++++++"
	model1 = DecisionTree.trainRegressor(trainingData, categoricalFeaturesInfo={}, impurity='variance', maxDepth=4, maxBins=32)

	####### Evaluate model on test instances and compute test error########
	predictions = model1.predict(testData.map(lambda x: x.features))
	labelsAndPredictions = testData.map(lambda lp: lp.label).zip(predictions)
	testMSE = labelsAndPredictions.map(lambda (v, p): (v - p) * (v - p)).sum() / float(testData.count())
	print('Test Mean Squared Error = ' + str(testMSE))
	print('================== Learned regression tree model ====================')
	print(model1.toDebugString())
	print(userid)
	input_data = get_input_data(userid[-20:-2])
	#features = vector.dense(result)
	prediction_value = model1.predict(input_data)
	print(prediction_value)
	post_prediction(userid[-20:-2],prediction_value)




def parsePoint(line):
    """
    Parse a line of text into an MLlib LabeledPoint object.
    """
    values = [float(s) for s in line.strip().split(',')]
    if values[0] == -1: # Convert -1 labels to 0 for MLlib
        values[0] = 0
    elif values[0] > 0:
        values[0] = 1
    return LabeledPoint(values[0], values[1:])


## need to write the http get request to get the data
def get_input_data(userid):
	print(userid)
	print "Details from CGI Get request"
	print(userid)
	httpServ = httplib.HTTPConnection("127.0.0.1", 80)
	httpServ.connect()
	httpServ.request('GET', '/pyget?user_id='+userid)
	response = httpServ.getresponse()
	if response.status == httplib.OK:
		print "Output from CGI Get request"
		respbody = response.read()

		uservalslist = respbody.split("-")

		uservalslist = map(float, uservalslist)


	httpServ.close()
	return uservalslist
##	return [57.0,1.0,2.0,124.0,261.0,0.0,0.0,141.0,0.0,0.3,1.0,0.0,7.0]
##  return [45.0, 1.0, 124.0, 12.0, 1.0, 3.0, 34.0, 54.0, 46.0, 34.0, 43.0, 123.0, 2.0]

## need to write the http get request to get the data
def post_prediction(userid,prediction_val):

	print "posting data ok"
	print("==============================Prediction======================================")
	print(userid)
	print(prediction_val)
	httpServ = httplib.HTTPConnection("127.0.0.1", 80)
	httpServ.connect()			
	httpServ.request('POST', '/pypost/', 'action=prediction&pred_per=%s&user_id=%s' % (prediction_val,userid))
	response = httpServ.getresponse()
	if response.status == httplib.OK:
		print "Output from CGI request"
		respbody = response.read()
	else :
		print "no response"
		respbody = response.read()
	httpServ.close()


userid = str(sys.argv)
run_decision_tree(userid)	

