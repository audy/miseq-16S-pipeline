# download greengenes

set -e
set -x

curl ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz \
  | gunzip | tar -xvf - \
    gg_13_8_otus/taxonomy/97_otu_taxonomy.txt \
    gg_13_8_otus/trees/97_otus.tree \
    gg_13_8_otus/rep_set/97_otus.fasta

# build search databasee
usearch \
  -makeudb_usearch gg_13_8_otus/rep_set/97_otus.fasta \
  -output gg_13_8_otus/rep_set/97_otus.fasta.udb
