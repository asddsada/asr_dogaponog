rm -rf exp/nnet2_online/decode_dev
steps/online/nnet2/decode.sh --config conf/decode.config --cmd utils/run.pl \
  --nj 2 --per-utt true --online true exp/nnet2_online/graph \
  data/dev exp/nnet2_online/decode_dev
cat exp/nnet2_online/decode_dev/scoring_kaldi/best_wer