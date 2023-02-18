#!/bin/bash
# # SBATCH -o /home/%u/slogs/sl_%A.out
# # SBATCH -e /home/%u/slogs/sl_%A.out
#SBATCH -N 1	  # nodes requested
#SBATCH -n 1	  # tasks requested
#SBATCH --gres=gpu:1  # use 1 GPU
#SBATCH --mem=14000  # memory in Mb
#SBATCH --partition=ILCC_GPU
#SBATCH -t 6-00:00:00  # time requested in hour:minute:seconds
#SBATCH --cpus-per-task=4

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
PROJECT_NAME="spike-protein-gan"
echo "Activating conda environment: ${PROJECT_NAME}"
conda activate ${PROJECT_NAME}

echo "Moving input data to the compute node's scratch space: $SCRATCH_DISK"
src_path=/home/${USER}/${PROJECT_NAME}/datasets/
dest_dataset_path=${SCRATCH_HOME}/${PROJECT_NAME}/datasets/
mkdir -p ${dest_dataset_path}  # make it if required
rsync --archive --update --compress --progress ${src_path}/ ${dest_dataset_path}

src_model_checkpoint_path=/home/${USER}/${PROJECT_NAME}/data/models/outcome-models/los_umlsbert_average_k5.pt
dest_model_checkpoint_path=${SCRATCH_HOME}/${PROJECT_NAME}/data/models/outcome-models/los_umlsbert_average_k5.pt
mkdir -p ${dest_path}  # make it if required
rsync --archive --update --compress --progress ${src_model_checkpoint_path} ${dest_model_checkpoint_path}

OUTPUT_DIR=${SCRATCH_HOME}/${PROJECT_NAME}/outputs/

echo "Running LOS benchmarking"
cd outcome-prediction/
python run_outcome_prediction.py 
  --train ${dest_path}/length_of_stay/LOS_WEEKS_adm_train.csv \
  --dev ${dest_path}/length_of_stay/LOS_WEEKS_adm_val.csv \
  --test ${dest_path}/length_of_stay/LOS_WEEKS_adm_test.csv \
  --init_model "bionlp/bluebert_pubmed_mimic_uncased_L-12_H-768_A-12" \
  --out_dir ${OUTPUT_DIR} \
  --checkpoint ${dest_model_checkpoint_path} \
  --outcome los \
  --do_test \
  --strategy average \
  --lit_dir ../data/los_reranked_final \
  --num_top_docs 5


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
