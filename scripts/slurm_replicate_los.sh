#!/bin/bash
# # SBATCH -o /home/%u/slogs/sl_%A.out
# # SBATCH -e /home/%u/slogs/sl_%A.out
#SBATCH -N 1	  # nodes requested
#SBATCH -n 1	  # tasks requested
#SBATCH --gres=gpu:1  # use 1 GPU
#SBATCH --mem=14000  # memory in Mb
#SBATCH --partition=ILCC_GPU
#SBATCH -t 6-00:00:00  # time requested in hour:minute:seconds
#SBATCH --cpus-per-task=3

echo "Job running on ${SLURM_JOB_NODELIST}"

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "Job started: $dt"

echo "Setting up bash enviroment"
source ~/.bashrc
set -e
SCRATCH_DISK=/disk/scratch
SCRATCH_HOME=${SCRATCH_DISK}/${USER}
mkdir -p ${SCRATCH_HOME}

# Activate your conda environment
ENV_NAME=beep-env
echo "Activating conda environment: ${ENV_NAME}"
conda activate ${ENV_NAME}

PROJECT_NAME="BEEP"
echo "Moving input data to the compute node's scratch space: $SCRATCH_DISK"
src_path=/home/${USER}/${PROJECT_NAME}/datasets/
dest_dataset_path=${SCRATCH_HOME}/${PROJECT_NAME}/datasets/
mkdir -p ${dest_dataset_path}  # make it if required
rsync --archive --update --compress --progress ${src_path}/ ${dest_dataset_path}

src_model_checkpoint_path=/home/${USER}/${PROJECT_NAME}/data/models/outcome-models/
dest_model_checkpoint_path=${SCRATCH_HOME}/${PROJECT_NAME}/data/models
mkdir -p ${dest_model_checkpoint_path}  # make it if required
dest_model_checkpoint_path=${dest_model_checkpoint_path}/outcome-models
mkdir -p ${dest_model_checkpoint_path}
rsync --archive --update --compress --progress ${src_model_checkpoint_path} ${dest_model_checkpoint_path}

src_retrieved_docs_path=/home/${USER}/${PROJECT_NAME}/data/los_reranked_final/
dest_retrieved_docs_path=${SCRATCH_HOME}/${PROJECT_NAME}/data/los_reranked_final/
mkdir -p ${dest_retrieved_docs_path}  # make it if required
rsync --archive --update --compress --progress ${src_retrieved_docs_path} ${dest_retrieved_docs_path}

OUTPUT_DIR=${SCRATCH_HOME}/${PROJECT_NAME}/outputs/

echo "Running LOS benchmarking"
cd outcome-prediction/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${CONDA_PREFIX}/lib
python run_outcome_prediction.py \
--train ${dest_dataset_path}/length_of_stay/LOS_WEEKS_adm_train.csv \
--dev ${dest_dataset_path}/length_of_stay/LOS_WEEKS_adm_val.csv \
--test ${dest_dataset_path}/length_of_stay/LOS_WEEKS_adm_test.csv \
--init_model "bionlp/bluebert_pubmed_mimic_uncased_L-12_H-768_A-12" \
--out_dir ${OUTPUT_DIR} \
--checkpoint ${dest_model_checkpoint_path}/los_bluebert_$1_k$2.pt \
--outcome los \
--do_test \
--strategy $1 \
--lit_dir ${dest_retrieved_docs_path} \
--num_top_docs $2


OUTPUT_HOME=${PWD}/exps/
mkdir -p ${OUTPUT_HOME}
rsync --archive --update --compress --progress ${OUTPUT_DIR} ${OUTPUT_HOME}

# Cleanup
rm -rf ${OUTPUT_DIR}

echo ""
echo "============"
echo "job finished successfully"
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "Job finished: $dt"
