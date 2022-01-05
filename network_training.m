%% Deep Learning - ResNet50
clear all;close all;clc
%% Load images

load( 'trainImages.mat' );
load( 'validationImages.mat' );
load('testImages.mat')

data1 = cat(4, trainImagesEye, validationImagesEye);
dataAll = cat(4, data1, test_Images_eye);
dsXTest = arrayDatastore(dataAll,'IterationDimension',4);
dsXTest.ReadSize = 1;
dsImage = transform(dsXTest,@classificationAugmentationPipeline);

%% Load labels

path_to_dir = 'C:\Users\pnmd36\Desktop\praca';

train_labels_saved = strcat(path_to_dir,'\Train_labels.csv');
validation_labels_saved = strcat(path_to_dir,'\Validation_labels.csv');
test_labels_saved = strcat(path_to_dir,'\Test_labels.csv');

train_labels = readmatrix(train_labels_saved);
validation_labels = readmatrix(validation_labels_saved);
test_labels = readmatrix(test_labels_saved);

labels = vertcat(train_labels, validation_labels, test_labels');
YTest = categorical(labels,[0 1 2 3],{'very low engagement', 'low engagement', 'high engagement', 'very high engagement'});
dsLabel = arrayDatastore(YTest);

%% Load features

train_features_saved = strcat(path_to_dir,'\Train_features.csv');
validation_features_saved = strcat(path_to_dir,'\Validation_features.csv');
test_features_saved = strcat(path_to_dir,'\Test_features.csv');

train_features = readmatrix(train_features_saved);
validation_features = readmatrix(validation_features_saved);
test_features = readmatrix(test_features_saved);

features = vertcat(train_features, validation_features, test_features);

dsFeature = arrayDatastore(features);

dsCombined = combine(dsImage,dsFeature, dsLabel);

%% Split data 

nImg = numel(labels);
numTrain = floor(0.70 * nImg);
numVal = floor(0.15 * nImg);
Idx = randperm(nImg);
idxTrain = Idx(1:numTrain);
idxVal = Idx(numTrain+1:numTrain+numVal);
idxTest = Idx(numTrain+numVal+1:nImg);
dsTrain = subset(dsCombined,idxTrain);
dsVal = subset(dsCombined,idxVal);
dsTest = subset(dsCombined,idxTest);

%% Show images with labels

numTrainImages = numel(labels);
idx = randperm(numTrainImages,16);
figure
for i = 1:16
    subplot(4,4,i)
    imshow(dataAll(:,:,:,idx(i)))
    title(char(YTest(idx(i))))
end

%% Load ResNet50

net = resnet50;
lgraph = layerGraph(net);
plot(lgraph)

inputSize = net.Layers(1).InputSize;

%% Adapt the network to the new learning

numClasses = numel(categories(YTest));

lgraph = replaceLayer(lgraph,'fc1000',...
  fullyConnectedLayer(numClasses,'Name','fc4', ...
  'WeightLearnRateFactor', 10, ...
  'BiasLearnRateFactor', 10));
lgraph = replaceLayer(lgraph,'fc1000_softmax',...
  softmaxLayer('Name','fc4_softmax'));
lgraph = replaceLayer(lgraph,'ClassificationLayer_fc1000',...
  classificationLayer('Name','ClassificationLayer_fc4'));

layers = lgraph.Layers;
connections = lgraph.Connections;
lgraph = createLgraphUsingConnections(layers,connections);

%% Additional layers

fc17 =  fullyConnectedLayer(17,'Name','fc17');
lgraph = addLayers(lgraph, fc17);
lgraph = disconnectLayers(lgraph,'avg_pool','fc4');
lgraph = connectLayers(lgraph, 'avg_pool', 'fc17');
lgraph = connectLayers(lgraph, 'fc17', 'fc4');

concat = concatenationLayer(1,2,'Name','concat');
lgraph = addLayers(lgraph, concat);
lgraph = connectLayers(lgraph, 'fc17', 'concat/in1');

featureInput = imageInputLayer([1 17],'Name','features', 'Normalization','rescale-zero-one', 'Min', 0, 'Max', 5 );
lgraph = addLayers(lgraph, featureInput);

fc17_features =  fullyConnectedLayer(17,'Name', 'fc17_features');
lgraph = addLayers(lgraph, fc17_features);
lgraph = connectLayers(lgraph, 'features', 'fc17_features');

lgraph = connectLayers(lgraph, 'fc17_features', 'concat/in2');

lgraph = disconnectLayers(lgraph,'fc17','fc4');
lgraph = connectLayers(lgraph, 'concat', 'fc4');

plot(lgraph);


%% Training

options = trainingOptions('sgdm',...
    'InitialLearnRate',0.001,...
    'MiniBatchSize',32,...
    'MaxEpochs',5,...
    'Momentum',0.9,...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.5,...
    'LearnRateDropPeriod',2,...
    'Verbose',true,...
    'Plots','training-progress',...
    'ValidationData',dsVal,...
    'Shuffle','every-epoch', ...
    'ValidationFrequency',50);

netTransfer = trainNetwork(dsTrain, lgraph,options);

save network netTransfer

%% Label test array

nTest = nImg  - numTrain - numVal;
testLabels = [];
for k = 1 : nTest    
    testLabels = vertcat(testLabels,YTest(idxTest(k))); 
end

%% Images test array

nTest = nImg  - numTrain - numVal;
testImages = [];
for k = 1 : nTest    
    testImages(:,:,:,k) = dataAll(:,:,:,idxTest(k));
end

%% Test

nTest = nImg  - numTrain - numVal;
testLabels = [];
for k = 1 : nTest    
    testLabels = vertcat(testLabels,YTest(idxTest(k))); 
end

nTest = nImg  - numTrain - numVal;
testImages = [];
for k = 1 : nTest    
    testImages(:,:,:,k) = dataAll(:,:,:,idxTest(k));
end

[YPredT,scoresT] = classify(netTransfer,dsTest);
YValidationT = testLabels;
accuracyT = 100*mean(YPredT == YValidationT);
disp(['Dokladnosc (zbior testowy) = ' num2str(accuracyT,'%2.1f'), '%'])

figure('Units','normalized','Position',[0.2 0.2 0.4 0.4]);
cm = confusionchart(YValidationT,YPredT);
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';

%% View some of the images with their predictions.
idx = randperm(size(testImages,4),9);
figure
for i = 1:9
    subplot(3,3,i)
    I = testImages(:,:,:,idx(i));
    imshow(I)
    label = string(YPredT(idx(i)));
    title({["Predicted Label: " + label + " " + num2str(100*max(scoresT(idx(i), :)),3)+"%"] ["Correct Label: " + string(YValidationT(idx(i)))]});

end
%% Validation 

valLabels = [];
for k = 1 : numVal    
   valLabels = vertcat(valLabels,YTest(idxVal(k))); 
end

valImages = [];
for k = 1 : numVal    
    valImages(:,:,:,k) = dataAll(:,:,:,idxVal(k));
end

[YPredV,scoresV] = classify(netTransfer,dsVal);
YValidationV = valLabels;

figure('Units','normalized','Position',[0.2 0.2 0.4 0.4]);
cm = confusionchart(YValidationV,YPredV);
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';

accuracyV = 100*mean(YPredV == YValidationV);
disp(['Dokladnosc (zbior walidacyjny) = ' num2str(accuracyV,'%2.1f'), '%'])

