%% Extract frames with features
clear all;close all;clc
%% Define directory paths

path_to_dir = 'C:\Users\pnmd36\Desktop\praca';
validation_dir = '\DAiSEE\DataSet\Validation';
validation_csv = '\DAiSEE\Labels\ValidationLabels.csv';
% path to OpenFace
open = 'C:\Users\pnmd36\Desktop\OpenFace\OpenFace_2.2.0_win_x64\OpenFace_2.2.0_win_x64\FeatureExtraction.exe -f "';

very_high_engagement = '\validation\very high engagement\';
very_high_engagement_data = '\validation\very_high_data\';
path_very_high_data = 'C:\\Users\\pnmd36\\Desktop\\praca\\validation\\very_high_data\\';

high_engagement = '\validation\high engagement\';
high_engagement_data = '\validation\high_data\';
path_high_data = 'C:\\Users\\pnmd36\\Desktop\\praca\\validation\\high_data\\';

very_low_engagement = '\validation\very low engagement\';
very_low_engagement_data = '\validation\very_low_data\';
path_very_low_data = 'C:\\Users\\pnmd36\\Desktop\\praca\\validation\\very_low_data\\';

low_engagement = '\validation\very low engagement\';
low_engagement_data = '\validation\low_data\';
path_low_data = 'C:\\Users\\pnmd36\\Desktop\\praca\\validation\\low_data\\';

patch_to_Validation = strcat(path_to_dir, validation_dir);
path_validation_csv = strcat(path_to_dir, validation_csv);
very_high_engagement_dir =  strcat(path_to_dir, very_high_engagement);
very_high_engagement_data_dir =  strcat(path_to_dir, very_high_engagement_data);

high_engagement_dir =  strcat(path_to_dir, high_engagement);
high_engagement_data_dir =  strcat(path_to_dir, high_engagement_data);

low_engagement_dir =  strcat(path_to_dir, low_engagement);
low_engagement_data_dir =  strcat(path_to_dir, low_engagement_data);

very_low_engagement_dir =  strcat(path_to_dir, very_low_engagement);
very_low_engagement_data_dir =  strcat(path_to_dir, very_low_engagement_data);

T = readtable(path_validation_csv);
ValidationLabels = convertvars(T,'ClipID','string');

T_Engagement = table2array(ValidationLabels(:,{'Engagement'}));
Labels = table2array(ValidationLabels(:,{'ClipID'}));

T = table(T_Engagement,'RowNames',Labels);

files = dir(patch_to_Validation);

dirFlags = [files.isdir];
subFolders = files(dirFlags);
cd(patch_to_Validation);

allFileNames = {subFolders(:).name};

%matrix with labels
matrix_labels = [];
%matrix with features
matrix_features = [];
%matrix with Images
Images = [];
i = 1; 

%% 
for k = 3 : length(allFileNames)-1
    fprintf('allFileNamesK{%d} = %s\n', k, allFileNames{k});
    % Get a list of all files and folders in this folder.
    files2 = dir([allFileNames{k}]);
    dirFlags2 = [files2.isdir];
    % Extract only directories.
    subFolders2 = files2(dirFlags2);
    
    cd(allFileNames{k});
    allFileNames2 = {subFolders2(:).name};

    for l = 3 : length(allFileNames2)
            
        cd(allFileNames2{l});
        
        file_name = allFileNames2{l};
        extention = '.avi';
        video_full_name = strcat(file_name,extention);
        fprintf('s: %s\n', video_full_name);
        fprintf('allFileNamesL{%d} = %s\n', l, allFileNames2{l});
        flag = 0;
        
        try
            current_label = table2array(T({video_full_name}, 1));
        catch ME
            if (strcmp(ME.identifier, 'MATLAB:table:UnrecognizedRowName'))
                flag = -1;
                display("No .avi file or without label");
            end
        end
        
        if (flag == -1)
            extention = '.mp4';
            video_full_name = strcat(file_name,extention);
            try
                current_label = table2array(T({video_full_name}, 1));
            catch ME
                if (strcmp(ME.identifier, 'MATLAB:table:UnrecognizedRowName'))
                    cd ..
                    display("File without label");
                    continue
                end
            end
        end
                
        % import the video file
        obj = VideoReader(video_full_name);
        vid = read(obj);
        
        % read the total number of frames
        frames = obj.NumFrames;
                
       % file format of the frames to be saved in
        ST ='.jpg';
        
        if current_label == 0
            fprintf('Very low\n');
            for x = 1 : 5 : frames
                matrix_labels = horzcat(matrix_labels,current_label);
                lab = x;
                
                frame_name_s = sprintf('%s_%d.jpg', file_name, x);
                full_frame_name = strcat(path_very_low_data, frame_name_s);
                Vid = vid(:, :, :, x);
                imwrite(Vid, full_frame_name);

                directory = sprintf('" -format_aligned jpg -nomask -gaze -simalign -out_dir %s', very_low_engagement_data_dir);

                command1 = strcat(open, full_frame_name);
                command2 = strcat(command1, directory);
                status = system(command2);

                csv_file = sprintf('%s_%d.csv', file_name, x);
                csv_file_to_move = strcat(very_low_engagement_data_dir, csv_file);

                M = readmatrix(csv_file_to_move);
                m1 = M(:, [6:13]);
                matrix_features = vertcat(matrix_features,m1);            

                file_name_number = sprintf('%s_%d', file_name, x);
                aligned_file = strcat(very_low_engagement_data_dir, file_name_number,'_aligned\frame_det_00_000001.jpg');
                jpg_file = sprintf('%s_%d.jpg', file_name, x);
                patch2 = strcat(very_low_engagement_dir, jpg_file);

                I = imread(aligned_file);
                Images(:,:,:,i) = im2double(I);
                i =i+1;                   
            end
            cd ..
        elseif current_label == 1
            fprintf('Low\n');
            for x = 1 : 30 : frames            
                matrix_labels = horzcat(matrix_labels,current_label);
                lab = x;
                
                frame_name_s = sprintf('%s_%d.jpg', file_name, x);
                full_frame_name = strcat(path_low_data, frame_name_s);
                Vid = vid(:, :, :, x);
                imwrite(Vid, full_frame_name);

                directory = sprintf('" -format_aligned jpg -nomask -gaze -simalign -out_dir %s', low_engagement_data_dir);

                command1 = strcat(open, full_frame_name);
                command2 = strcat(command1, directory);
                status = system(command2);

                csv_file = sprintf('%s_%d.csv', file_name, x);
                csv_file_to_move = strcat(low_engagement_data_dir, csv_file);

                M = readmatrix(csv_file_to_move);
                m1 = M(:, [6:13]);
                matrix_features = vertcat(matrix_features,m1);            

                file_name_number = sprintf('%s_%d', file_name, x);
                aligned_file = strcat(low_engagement_data_dir, file_name_number,'_aligned\frame_det_00_000001.jpg');
                jpg_file = sprintf('%s_%d.jpg', file_name, x);
                patch2 = strcat(low_engagement_dir, jpg_file);

                I = imread(aligned_file);
                Images(:,:,:,i) = im2double(I);
                i =i+1;                   
            end
            cd ..
        elseif current_label == 2
            fprintf('High\n');
            x = 150;
            matrix_labels = horzcat(matrix_labels,current_label);
            
            frame_name_s = sprintf('%s_%d.jpg', file_name, x);
            full_frame_name = strcat(path_high_data, frame_name_s);
            Vid = vid(:, :, :, x);
            imwrite(Vid, full_frame_name);
            
            directory = sprintf('" -format_aligned jpg -nomask -gaze -simalign -out_dir %s', high_engagement_data_dir);

            command1 = strcat(open, full_frame_name);
            command2 = strcat(command1, directory);
            status = system(command2);

            csv_file = sprintf('%s_%d.csv', file_name, x);
            csv_file_to_move = strcat(high_engagement_data_dir, csv_file);

            M = readmatrix(csv_file_to_move);
            m1 = M(:, [6:13]);
            matrix_features = vertcat(matrix_features,m1);            

            file_name_number = sprintf('%s_%d', file_name, x);
            aligned_file = strcat(high_engagement_data_dir, file_name_number,'_aligned\frame_det_00_000001.jpg');
            jpg_file = sprintf('%s_%d.jpg', file_name, x);
            patch2 = strcat(high_engagement_dir, jpg_file);

            I = imread(aligned_file);
            Images(:,:,:,i) = im2double(I);
            i =i+1;                   
            cd ..
        elseif current_label == 3
            fprintf('Very high\n');
            x= 150;
            matrix_labels = horzcat(matrix_labels,current_label);
            
            frame_name_s = sprintf('%s_%d.jpg', file_name, x);
            full_frame_name = strcat(path_very_high_data, frame_name_s);
            Vid = vid(:, :, :, x);
            imwrite(Vid, full_frame_name);
            
            directory = sprintf('" -format_aligned jpg -nomask -gaze -simalign -out_dir %s', very_high_engagement_data_dir);

            command1 = strcat(open, full_frame_name);
            command2 = strcat(command1, directory);
            status = system(command2);

            csv_file = sprintf('%s_%d.csv', file_name, x);
            csv_file_to_move = strcat(very_high_engagement_data_dir, csv_file);

            M = readmatrix(csv_file_to_move);
            m1 = M(:, [6:13]);
            matrix_features = vertcat(matrix_features,m1);            

            file_name_number = sprintf('%s_%d', file_name, x);
            aligned_file = strcat(very_high_engagement_data_dir, file_name_number,'_aligned\frame_det_00_000001.jpg');
            jpg_file = sprintf('%s_%d.jpg', file_name, x);
            patch2 = strcat(very_high_engagement_dir, jpg_file);
            
            I = imread(aligned_file);
            Images(:,:,:,i) = im2double(I);
            i =i+1;                   
            cd ..
        else
            cd ..
        end
    end 
    cd ..
end
%% Save data

matrix_labels = matrix_labels';

validation_labels_saved = strcat(path_to_dir,'\Validation_labels.csv');
writematrix(matrix_labels, validation_labels_saved);
validation_features_saved = strcat(path_to_dir,'\Validation_features.csv');
writematrix(matrix_features, validation_features_saved);

validationImages  = Images;
save validationImages validationImages