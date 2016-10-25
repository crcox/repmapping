require 'rake'
require 'rake/clean'

tmp = ENV['DIMENSION_NORM'] || 5
DIMENSION_NORM = tmp.to_i
FEATURE_FILES = Rake::FileList.new("*_features.csv")
MODEL_FILES_TO_BUILD = FEATURE_FILES.sub("features","norm_model")
MODEL_FILES = Rake::FileList.new("*_{next,norm}_model.csv")
WORDS_TO_DROP = %W(bowling crow rain)

MODEL_FILES_TO_BUILD.zip(FEATURE_FILES).each do |target, source|
  file target => [source] do
    sh "./R/derive_model.R #{DIMENSION_NORM} #{source}|sed '1d' > #{target}"
  end
end

MODEL_FILES.each do |m|
  dropExpressions = []
  WORDS_TO_DROP.each do |w|
    dropExpressions.push("-e '/^#{w}/d'")
  end
  sh "sed -i #{dropExpressions.join(' ')} #{m}"
end

desc "Generate models from processed feature norms."
task :generate => MODEL_FILES_TO_BUILD
task :default => [:generate]

CLOBBER.include(MODEL_FILES_TO_BUILD)
