cd slrim/
echo -e '\n******* prepare arpa*******************************\n'
cut -f 2- -d ' '  --output-delimiter ' ' ../data/train/text | sort -u > sl.train
cut -f 2- -d ' '  --output-delimiter ' ' ../data/dev/text | sort -u > sl.dev
ngram-count -write-vocab sl.vocab -text sl.train
sed -n '5,$p' sl.vocab | sort -u > gowajee.vocab
cp gowajee.vocab ../data/gowajee.vocab
cp gowajee.vocab ../g2p/gowajee.vocab
#cut -f 1 -d$' ' sl.manual.classes | sort -u >> gowajee.vocab


echo -e '\n******* train  arpa*******************************\n'
#ngram-count -vocab sl.vocab -text sl.train -order 10 -wbdiscount -maxent-convert-to-arpa -lm gowajee.arpa
#ngram-count -vocab sl.vocab -text sl.train -order 10 -wbdiscount -lm sl.lm
#ngram -order 10 -lm sl.lm -classes sl.manual.classes -expand-classes 10 -expand-exact 10 -write-lm sl.mclass.lm

./build_class_ngram  sl.manual.classes sl.train 3 sl.vocab sl.mclass.lm
ngram -order 0 -lm sl.mclass.lm -ppl sl.dev
ngram -order 1 -lm sl.mclass.lm -ppl sl.dev
ngram -order 2 -lm sl.mclass.lm -ppl sl.dev
ngram -order 3 -lm sl.mclass.lm -ppl sl.dev
ngram -order 4 -lm sl.mclass.lm -ppl sl.dev
ngram -order 5 -lm sl.mclass.lm -ppl sl.dev
ngram -order 6 -lm sl.mclass.lm -ppl sl.dev
ngram -order 7 -lm sl.mclass.lm -ppl sl.dev
ngram -order 8 -lm sl.mclass.lm -ppl sl.dev
ngram -order 9 -lm sl.mclass.lm -ppl sl.dev
ngram -order 10 -lm sl.mclass.lm -ppl sl.dev
#cp tmp.lm gowajee.arpa
cp sl.mclass.lm gowajee.arpa
rm gowajee.arpa.gz
gzip gowajee.arpa
cp gowajee.arpa.gz ../data/

cd ../g2p
echo -e '\n*********** g2p *******************************\n'
g2p.py --model model-5 --encoding UTF-8 --apply gowajee.vocab > l.txt
cut -f 2- -d$'\t' l.txt | tr ' ' $'\n' | sort -u > ../data/local/dict/nonsilence_phones.txt
echo -e '<SIL>\tSIL\n<UNK>\tUNK' >> l.txt
sort -u l.txt > lexicon.txt
g2p.py --model model-5 --encoding UTF-8 --apply gowajee.vocab --variants-number 1 > l.txt
cut -f 1,3- -d '0' l.txt > lp.txt
echo -e '<SIL>\t1.0\tSIL\n<UNK>\t1.0\tUNK' >> lp.txt
sort -u lp.txt > lexiconp.txt

cp lexicon.txt ../data/local/dict/lexicon.txt
cp lexiconp.txt ../data/local/dict/lexiconp.txt

cd ..
echo -e '\n******* prepare_lang *******************************\n'
./utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

echo -e '\n******* format_lm *******************************\n'
./utils/format_lm.sh data/lang data/gowajee.arpa.gz data/local/dict/lexicon.txt data/lang
./utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

echo -e '\n*******  HCLG  *******************************\n'
./utils/mkgraph.sh data/lang exp/nnet2_online exp/nnet2_online/graph

echo -e '\n*******  decodde  *******************************\n'
rm -rf exp/nnet2_online/decode_dev
./steps/online/nnet2/decode.sh --config conf/decode.config --cmd utils/run.pl \
  --nj 2 --per-utt true --online true exp/nnet2_online/graph \
  data/dev exp/nnet2_online/decode_dev
grep WER exp/nnet2_online/decode_dev/wer_*
cat exp/nnet2_online/decode_dev/scoring_kaldi/best_wer