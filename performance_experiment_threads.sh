#!/bin/bash

declare -A options
options[yolov3]="yolov3_adas_pruned_0_9 yolov3_voc "
options[classification]="resnet50 resnet18 inception_v1 inception_v2 inception_v3 inception_v4 mobilenet_v2 squeezenet inception_resnet_v2_tf inception_v1_tf inception_v2_tf inception_v3_tf inception_v4_2016_09_09_tf mobilenet_v1_0_25_128_tf mobilenet_v1_0_5_160_tf mobilenet_v1_1_0_224_tf mobilenet_v2_1_0_224_tf mobilenet_v2_1_4_224_tf mobilenet_edge_0_75_tf mobilenet_edge_1_0_tf resnet_v1_101_tf resnet_v1_152_tf resnet_v1_50_tf resnet_v2_101_tf resnet_v2_152_tf resnet_v2_50_tf vgg_16_tf vgg_19_tf MLPerf_resnet50_v1.5_tf resnet50_tf2 inception_v3_tf2 mobilenet_1_0_224_tf2 squeezenet_pt resnet50_pt inception_v3_pt efficientNet-edgetpu-S_tf efficientNet-edgetpu-M_tf efficientNet-edgetpu-L_tf efficientnet-b0_tf2 ofa_resnet50_0_9B_pt person-orientation_pruned_558m_pt ofa_depthwise_res50_pt mobilenet_v3_small_1_0_tf2"
options[segmentation]="fpn semantic_seg_citys_tf2 unet_chaos-CT_pt FPN-resnet18_Endov SemanticFPN_cityscapes_pt ENet_cityscapes_pt mobilenet_v2_cityscapes_tf SemanticFPN_Mobilenetv2_pt"
options[yolov2]="yolov2_voc yolov2_voc_pruned_0_66 yolov2_voc_pruned_0_71 yolov2_voc_pruned_0_77"
options[refinedet]="refinedet_baseline refinedet_pruned_0_8 refinedet_pruned_0_92 refinedet_pruned_0_96 refinedet_VOC_tf"
options[ssd]="ssd_pedestrian_pruned_0_97 ssd_traffic_pruned_0_9 ssd_adas_pruned_0_95 ssd_mobilenet_v2 mlperf_ssd_resnet34_tf"
options[tfssd]="ssd_mobilenet_v1_coco_tf ssd_mobilenet_v2_coco_tf ssd_resnet_50_fpn_coco_tf ssd_inception_v2_coco_tf ssdlite_mobilenet_v2_coco_tf"
options[yolov4]="yolov4_leaky_spp_m yolov4_leaky_spp_m_pruned_0_36"
options[yolovx]="tsd_yolox_pt"
options[posedetect]="sp_net"


base="/home/root/coco/modelos_COCO"
for type in yolov2 yolov3 yolov4 yolovx posedetect classification segmentation refinedet ssd tfssd
do

  path=$base/$type
  cd $path

  for model in ${options[$type]}
  do
    for threads in {1..20}
    do
      # each execution
      if [[ $model!=squeezenet && $model!=squeezenet_pt ]]
      then
        ./test_performance_$type $model las_imagenes.list -t$threads > tmp
      else
        ./test_performance_classification_squeezenet $model las_imagenes.list -t$threads > tmp
      fi

      # gets FPS E2E_mean and DPU_mean
      fps=$(cat tmp | grep FPS | cut -d"=" -f2)
      if [ -z "$fps" ]
      then
        fps=null
      fi

      e2e=$(cat tmp | grep E2E | cut -d"=" -f2)
      if [ -z "$e2e" ]
      then
        e2e=null
      fi

      dpu=$(cat tmp | grep DPU | cut -d"=" -f2)
      if [ -z "$dpu" ]
      then
        dpu=null
      fi
      rm -f tmp

      # generates a file with all the relevant data generated
      echo -n {\"type\": \"$type\", \"model\": \"$model\", \"threads\": \"$threads\", >> $base/performance_results.jsonl
      echo \"fps\": $fps, \"e2e\": $e2e, \"dpu\": $dpu} >> $base/performance_results.json
    done
  done
done
