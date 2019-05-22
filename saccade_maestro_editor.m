function   saccade_maestro_editor(data_dir)
    %This functions gets as input the directory that contain all the data
    %(other directories that contain maestro file) e.g:data_dir='C:\Users\Owner\Documents\Matan\Stroop effect project\Data-Maestro';
    %It adds saccades and blinks to the maestro files and edits the mark1 and mark2 vectors in the matlab structures of the files
    %Important: The function uses the getSaccades function of noga
    %'C:\Users\Owner\Documents\Matan\Code-General\Noga matlab functions\organize-master\getSaccades'
    a=dir(data_dir);
    CALIBRATE_VEL = 10.8826;
for n_s=3:length(a) %n_s for session nuber
    session=a(n_s).name;
    file=[data_dir,'\',session];
    cd(file);
    file_list=dir([file,'\',session(1),'*']);
    file_list=vertcat(file_list.name);
    %% 1. Get saccades as 2 vectors mark1 and mark2
    for trial=1:length(file_list)
        file_name=file_list(trial,:);
        raw_data = readcxdata(file_name);
        hVel=raw_data.data(3,:)/CALIBRATE_VEL;
        vVel=raw_data.data(4,:)/CALIBRATE_VEL;   
        blinks=raw_data.blinks;
        targets=raw_data.targets;
        [mark1,mark2] = getSaccades( hVel, vVel, blinks, targets );
        %% 2. Edit the maestro file
        raw_data.mark1 = mark1;
        raw_data.mark2 = mark2;
        editcxdata(file_name, raw_data);
    end
end