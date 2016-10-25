proc main {NETFILE TRAINFILE TESTFILE} {
  global env
  global Test
  if {![ info exists env(PATH) ]} {
    set env(PATH) "/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/crcox/bin"
  }

  file mkdir "wt"
  file mkdir "log"
  file mkdir "out"

  puts $NETFILE
  source $NETFILE
  source tcl/errorInUnits.tcl

  set NetName [getObj name]
  set iCV [lindex [file split $TRAINFILE] 1]
  set BaseName [join [list $NetName $iCV] "_"]
  set ErrorLog [file join "log" [join [list $BaseName "log"] "."]]
  set ResultFile [file join "out" [join [list $BaseName "csv"] "."]]

  set OutputLayer "features"

  setObject testGroupCrit 0.5
  setObject targetRadius 0
  setObject numUpdates 10000
  setObject weightDecay 0
  setObject batchSize 0
  setObject zeroErrorRadius 0
  setObject learningRate 0.075
  setObject momentum 0
  setObject reportInterval 100
  set SpikeThreshold 5.0
  set SpikeThresholdStepSize 1.5
  set TestEpoch 1

  resetNet

  puts $TRAINFILE
  loadExamples "$TRAINFILE" -set "train" -exmode PERMUTED
  useTrainingSet "train"

  puts $TESTFILE
  eval "loadExamples $TESTFILE -set test -exmode ORDERED"
  useTestingSet "test"

  set ErrorLogHandle [open $ErrorLog w]
  set ResultFileHandle [open $ResultFile w]

  errorInUnits $ResultFileHandle $OutputLayer

  for {set i 0} {$i < 25} {incr i} {
    set WeightFile [file join "wt" [join [list $BaseName $i "wt"] "."]]
    train -a steepest
    set err [getObj error]
    puts $ErrorLogHandle [format "%.2f" $err]
    errorInUnits $ResultFileHandle $OutputLayer
    saveWeights "$WeightFile"
  }

  close $ErrorLogHandle
  close $ResultFileHandle
  exit 0
}

if { [catch {main [lindex $argv 0] [lindex $argv 1] [lindex $argv 2]} msg] } {
  puts stderr "unexpected script error: $msg"
  puts "$::errorInfo"
  exit 1
}
