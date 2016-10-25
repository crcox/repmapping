Dependencies
============
- Ruby: Rake (shipped with Ruby)
- R: Rscript (shipped with R), argparser
- tcl:

Modeling the relationships among representational spaces
========================================================
This set of 37 stimuli was selected for use in the Sound-Picture fMRI
experiment conducted at the University of Manchester, UK by Matthew
Lambon Ralph and the Neuroscience and Aphasia Research Unit (NARU).

Their criteria for selection were:

 1. Each item had to be identifiable via a picture and a characteristic
    sound.
 2. The set of items needed to have conceptual structure that was
    relatively uncorrelated with the perceptual similarity structure of
    the image.

The conceptual structure was estimated using feature norms acquired at
NARU. There are important questions about how well conceptual structure
is captured by such feature norms. In the Knowledge and Concepts Lab at
the University of Wisconsin, we have been experimenting with an
alternative method of estimating latent conceptual similarity based on
human judgements in a variant of a match-to-sample task. The task
involves two alternatives an a reference item, and participants are
instructed to select which alternative is more similar to the reference
item. In general, the instructions may direct participants to a
particular dimension of similarity (perceptual vs. conceptual
similarity).

By posing participants with a large number of relatively unconstrained
similarity judgements, as opposed to attending to the features of
individual items in isolation, they may draw upon more varied and
nuanced relationships among items that ultimately draws out a richer
similarity structure. This procedure is implemented in the web-based
active-learning platform `NEXT discovery`.

Using `NEXT`, we collected a set of such similarity judgements based on
the same items. With this code base, we are attempting to compare the
representational spaces associated with the feature norms and with the
similarity judgements collected with NEXT.

Embedding human responses in a metric space
-------------------------------------------
Before comparing these two kinds of behavioral responses (feature norms
and similarity judgments), we first "embed" these response in "low rank"
metric spaces. Think about the metric space this way: suppose a two
dimensional space, like a table top, and all the items layed out in
front of you. The distance among each item corresponds to how
similar they are. Now, consider any three items on the table. Treat one
of them as the reference item, and the two others as alternatives (as in
the similarity judgment task). If you considered the "embedding" on the
table in front of you (the relationships among the items have been
"embedded" in two dimensions on the table top) as a model of the
conceptual space, then the alternative that is closer to the reference
item is the one that the model believes is more similar. In this way,
this "embedding" is a "model system" that can perform the similarity
task.

The appropriate layout of items can be determined through optimization.
The optimization is called "multidimensional scaling". For the feature
norms, we can use "classicial" (metric) multidimensional scaling,
and for the similarity judgements we us "nonmetric" multidimensional
scaling. The items are moved around in space until the model coordinates
capturate the relative distances between feature vectors, or model
performance agrees with as many of the similarity judgments as possible,
as the case may be.

As just described, it is easy to treat these embeddings as models that
can perform the similarity judgment task. However, if the embedding
derived from similarity judgements peforms better at predicting
similarity judgments, this would not be compelling evidence that
similarity judgments discovered a "better" conceptual structure.
Therefore, we are going to do the inverse as well: use the embeddings to
predict the feature vectors.

Predicting feature vectors from low-rank embeddings
---------------------------------------------------
This is a little more elaborate than modeling the similarity judgments.
In the simplest formulation, one would model each feature in turn. Each
item either will or will not have a feature, and we can use either the
embedding based on the feature norms or the embedding based on the
similarity judgments (from NEXT) to predict whether or not a given item
will have that feature. This can be accomplished with logistic
regression.

An alterative approach is to set up the problem in terms of a neural
network model. In its most basic formulation, there would be an input
unit for each dimension of the embedding, and one output unit for each
possible feature (over all items). Every input unit is connected to
every output. Connections can have positive or negative weights, and the
model will seek a set of weights that will activate the right pattern of
output units (features) given a pattern of input (the values on each
dimension of the input for a particular item, which is a coordinate in
the metric space).

In this neural network formuation, if you dropped all but a single
output feature, the problem would essentially reduce to logistic
regression.

In general, one can fit multi-layer neural networks, by including a
hidden layer between the input and output. This is not necessary, but it
allows for non-linear mappings between the input and the output.

> CRC: The models I have fit already included a 5-unit hidden layer.

The objective is to test whether the feature vector for each item (that
is, the pattern of `1`s and `0`s that flag which features an item has)
is better predicted based on the embedding derived from the very same
feature vectors, or the embedding derived from the similarity judgments
(from NEXT).

The procedure
=============
This code base expresses the procedures for preparing the feature
vectors, generating neural network models of the kind just described,
and fitting them to learn mappings between the two kinds of embedding
(feature norms vs. NEXT). The procedures are accessed via Rakefiles,
which are special `ruby` scripts that allow "task based"
workflows---they are kind of like Makefiles, but everything is in pure
`ruby`.

Note that there are two environment variables that will effect the steps
to follow:

 - `DIMENSION_NORM` (this should be set to the number of dimensions in the NORM
   based model (i.e., metric embedding).
 - `DIMENSION_NEXT` (this should be set to the number of dimensions in the NEXT
   based model (i.e., metric embedding).
 - `NHIDDEN` (will define the number of units in a hidden layer between
   input and output. If `0`, the hidden layer is ommitted.)

Once those variables are set, the following will prepare the files you
need for analysis:

 1. rake -f rake/norms.rake
 2. rake -f rake/models.rake
 3. rake -f rake/lens.rake
 4. (a) rake -f rake/lens.rake train # this will fit all models
 4. (b) rake -f rake/lens.rake out/combined\_norm\_combined\_0.csv # this
will fit a model that makes predictions about combined data, fitting
combined data, with the first holdout set.


