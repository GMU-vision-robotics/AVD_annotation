# AVD_annotation
| AVD_scenes | Hand Label | Point Cloud Generation | Label Propagation |
|--|--|--|--|
| HOME_001_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_002_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_003_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_004_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_005_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_006_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_007_1  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:
| HOME_008_1  | 
| HOME_010_1  | :heavy_check_mark: | :heavy_check_mark: | Ongoing
| HOME_011_1  | :heavy_check_mark: | :heavy_check_mark: | Ongoing
| HOME_013_1  | 
| HOME_014_1  | 
| HOME_014_2  |
| HOME_015_1  | 
| HOME_016_1  | :heavy_check_mark: | :heavy_check_mark: | Ongoing

## Annotation Pipeline Guide
**Hand Label Clean Up**

Open Matlab. Go to `root/annotation_hoiem`. `root/` refers to the `AVD_annotation` home directory.
Run `create_global_labels.m`,
1. add the room to label to directory list imdir, indir, outdir.
2. change 'video_index', refers to the Home you are going to label.
3. change 'startnum', refers to the image you start with.
4. To fix the mistakenly labeled object name, use the following two lines.
If the target object category is  'nature_valley_sweet_and_salty_nut_almond',
```
objects.name{iobj} = 'nature_valley_sweet_and_salty_nut_almond';
save(inname, 'objects');
```

**Point Cloud Generation**

Go to `root/label_prop`. Run `preprocess_label_propagation_script.m`,
1. put the avd_scene_folder, e.g. Home_006_01, under label_prop folder.
2. make sure 'final_label', 'intrinsic.mat' and 'spM' is inside.
3. Then run the 5 steps in `preprocess.m` script including  'select_ALL_FRAME', 'SELECT_KEY_FRAME', 'GENERATE_XYZworld', 'VISUALIZE_XYZworld', 'PRUNE_KEY_FRAME'.. We can skip the 4th step visualization by setting its flag into zero.
And don't forget to change the video_name and v_index to refer to the scene you are processing.
4. video 007, image 0007100040301 has undecoded depth image.

**Label Propagation**

Use the following commands to run `propagate_3dprojv7.m` to process scene 'Home_006_1', 'Home_004_1', 'Home_007_1', 'Home_010_1', 'Home_011_1', 'Home_016_1', 
The input 3 arguments refer to scene to process, start frame and end frame.
```
propagate_3dprojv7('Home_006_1', 1, 2412)
propagate_3dprojv7('Home_004_1', 1, 1488)
propagate_3dprojv7('Home_007_1', 1, 402)
propagate_3dprojv7('Home_007_1', 404, 1728)
propagate_3dprojv7('Home_010_1', 1, 1320)
propagate_3dprojv7('Home_011_1', 1, 1548)
propagate_3dprojv7('Home_016_1', 1, 1128)
```

