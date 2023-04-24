export DATA_DIR="/home/jovyan/work/Fariba_FSL_codes/TVB1"
cd $DATA_DIR
export INPUTS_DIR="$DATA_DIR/raw"
mkdir processed
export OUTPUTS_DIR="$DATA_DIR/processed"
flirt -in $INPUTS_DIR/T1_defaced.nii.gz -ref $INPUTS_DIR/post_implant_ct_defaced.nii.gz -out $OUTPUTS_DIR/t1_input.nii.gz -omat $OUTPUTS_DIR/results.mat

