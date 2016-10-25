require 'rake'
require 'rake/clean'

tmp = ENV['DIMENSION_NORM'] || 5
DIMENSION_NORM = tmp.to_i
tmp = ENV['DIMENSION_NEXT'] || 5
DIMENSION_NEXT = tmp.to_i
tmp = ENV['NHIDDEN'] || 0
NHIDDEN = tmp.to_i || 0
INPUTGROUPNAME = "embedding"
HIDDENGROUPNAME = "hidden"
OUTPUTGROUPNAME = "features"
FEATURE_FILES = Rake::FileList.new("*_features.csv")
MODEL_FILES_NORM = Rake::FileList.new("*_norm_model.csv")
MODEL_FILES_NEXT = Rake::FileList.new("*_next_model.csv")
MODEL_FILES = MODEL_FILES_NORM + MODEL_FILES_NEXT
EXAMPLE_FILES = []
NETWORK_FILES = []
RESULT_FILES = []

dir_list = []
(0...4).each do |m|
  directory File.join('ex',m.to_s)
  dir_list.push(File.join('ex',m.to_s))
end
directory File.join('in')
dir_list.push('in')
task :makedirs => dir_list

MODEL_FILES.product(FEATURE_FILES).each do |mfile,ffile|
  m = mfile.sub('_model.csv','')
  f = ffile.sub('_features.csv','')
  efile_base = "#{m}_#{f}"
  nfile = "in/#{m}_#{f}.in"
  NETWORK_FILES.push(nfile)
  file nfile => [ffile] do
    # minus one, because the first column is the row label
    nfeatures = %x( awk -F',' '{print NF; exit;}' #{ffile} ).to_i - 1

    File.open(nfile, 'w') do |net|
      net.write("addNet #{m}_#{f}\n")
      groups = []
      groups.push(INPUTGROUPNAME)
      if (MODEL_FILES_NORM.include? mfile) then
        net.write("addGroup #{INPUTGROUPNAME} #{DIMENSION_NORM} INPUT\n")
      else
        net.write("addGroup #{INPUTGROUPNAME} #{DIMENSION_NEXT} INPUT\n")
      end
      if (NHIDDEN>0) then
        groups.push(HIDDENGROUPNAME)
        net.write("addGroup #{HIDDENGROUPNAME} #{NHIDDEN}\n")
      end
      groups.push(OUTPUTGROUPNAME)
      net.write("addGroup #{OUTPUTGROUPNAME} #{nfeatures} OUTPUT\n\n")
      net.write("connectGroups #{groups.join(' ')}\n")
      #net.write("loadExamples #{efile}\n")
    end
  end
  (0...4).each do |iCV|
    efile_train = File.join('ex',iCV.to_s,"#{efile_base}_train.ex")
    EXAMPLE_FILES.push(efile_train)

    file efile_train => [mfile,ffile] do |target|
      features = File.open(ffile, 'r').to_enum
      model = File.open(mfile, 'r').to_enum
      ex = File.open("#{target}", 'w')

      ex.write("actI: 1\n")
      ex.write("actT: 1\n")
      ex.write("defI: 0\n")
      ex.write("defT: 0\n")
      ex.write(";\n\n")

      features.zip(model).each_with_index do |(featureBlob,modelBlob),i|
        if ( i % 4 != iCV ) then
          target = featureBlob.chomp.split(',')
          input = modelBlob.chomp.split(',')
          wT = target.shift
          wI = input.shift
          exit unless wT==wI
          name = wT
          input.collect! {|s| "%.4f" % s.to_f}
          target.collect! {|s| "%d" % s.to_i}
          ex.write("name: #{name}\n")
          ex.write("I: (#{INPUTGROUPNAME}) #{input.join(' ')}\n")
          ex.write("T: (#{OUTPUTGROUPNAME}) #{target.join(' ')}\n")
          ex.write(";\n")
        end
      end
    end

    efile_test = File.join('ex',iCV.to_s,"#{efile_base}_test.ex")
    EXAMPLE_FILES.push(efile_test)

    file efile_test=> [mfile,ffile] do
      features = File.open(ffile, 'r').to_enum
      model = File.open(mfile, 'r').to_enum
      ex = File.open("#{efile_test}", 'w')

      ex.write("actI: 1\n")
      ex.write("actT: 1\n")
      ex.write("defI: 0\n")
      ex.write("defT: 0\n")
      ex.write(";\n\n")

      features.zip(model).each_with_index do |(featureBlob,modelBlob),i|
        target = featureBlob.chomp.split(',')
        input = modelBlob.chomp.split(',')
        wT = target.shift
        wI = input.shift
        exit unless wT==wI
        name = wT
        input.collect! {|s| "%.4f" % s.to_f}
        target.collect! {|s| "%d" % s.to_i}
        ex.write("name: #{name}\n")
        ex.write("I: (#{INPUTGROUPNAME}) #{input.join(' ')}\n")
        ex.write("T: (#{OUTPUTGROUPNAME}) #{target.join(' ')}\n")
        ex.write(";\n")
      end
    end
  end
end
NETWORK_FILES.each do |nfile|
  (0...4).each do |iCV|
    base = File.basename(nfile,'.in')
    ex_train = File.join('ex',iCV.to_s,"#{base}_train.ex")
    ex_test = File.join('ex',iCV.to_s,"#{base}_test.ex")
    resultFile = File.join("#{base}_#{iCV}.csv")
    RESULT_FILES.push(resultFile)
    file resultFile => [nfile,ex_train,ex_test] do
      File.open('params.tcl','w') do |f|
        f.write("set argv [list \"#{nfile}\" \"#{ex_train}\" \"#{ex_test}\"]\n")
      end
      sh("cat params.tcl tcl/trainscript.tcl > trainscript_argv.tcl")
      sh("zsh -c '/home/chris/src/lens/lens -batch trainscript_argv.tcl'")
    end
  end
end
# Generate LENS example files
task :examples => EXAMPLE_FILES
# Generate LENS network files
task :networks => NETWORK_FILES
# Run LENS using the example and network file pairs
task :train => RESULT_FILES
task :default => [:makedirs,:examples,:networks]
CLOBBER.include(EXAMPLE_FILES)
CLOBBER.include(NETWORK_FILES)
CLOBBER.include(RESULT_FILES)
