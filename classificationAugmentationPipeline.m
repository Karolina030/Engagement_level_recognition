function [dataOut] = classificationAugmentationPipeline(dataIn)

dataOut = cell([size(dataIn,1),1]);

for idx = 1:size(dataIn,1)
    temp = dataIn{idx};
    
    temp = im2double(imresize(dataIn{idx},[224 224]));
    tform = randomAffine2d('Scale',[0.95,1.05],'Rotation',[-10 10]);
    outputView = affineOutputView(size(temp),tform);
    temp = imwarp(temp,tform,'OutputView',outputView);
    
    dataOut(idx) = {temp};
end

end