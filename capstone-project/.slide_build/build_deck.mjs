import fs from 'node:fs/promises';
import path from 'node:path';
import {FileBlob,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
import {applyPresentationChartFont} from 'file:///C:/Users/micha_o0x2g07/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations/container_tools/artifact_tool_utils.mjs';

const source='C:/Users/micha_o0x2g07/Downloads/Final Project EDA Presentation - Gavin, Michael, Thaddeus.pptx';
const p=await PresentationFile.importPptx(await FileBlob.load(source));
// Chart workbooks retain up to 15 significant digits. Twelve preserve the
// measured comparisons while avoiding meaningless floating-point tail digits.
const data=JSON.parse(await fs.readFile('.slide_build/data.json','utf8'),
  (_key,value)=>typeof value==='number'?Number(value.toPrecision(12)):value);
const template=p.slides.items[3];
const C={blue:'#2573AE',ink:'#1B3045',muted:'#526C84',pale:'#EDF3F7',orange:'#D55E00',gray:'#AAB6C0'};
const textStyle={fontSize:18.67,fill:C.muted};
const chartFrame={left:103.68,top:190,width:1065.6,height:370};
function newSlide(title,subtitle,takeaway,notes,index){
  const slide=template.duplicate();
  slide.moveTo(4+index);
  for(const image of [...slide.images.items]) image.delete();
  for(const shape of slide.shapes.items){
    const text=shape.text.toString();
    if(text==='How Lateral Hand Velocity Changes Over Time') shape.text=title;
    else if(text==='Participant A  |  Condition A  |  Slow targets  |  Three blocks') shape.text=subtitle;
    else if(text==='Velocity patterns diverge later in the movement; corrective direction is not yet verified.') shape.text=takeaway;
    else if(text==='3') shape.text=String(index+4);
  }
  slide.speakerNotes.text=notes;
  slide.speakerNotes.setVisible(true);
  return slide;
}
function formatChart(chart){
  applyPresentationChartFont(chart,{fontFamily:'Arial'});
  return chart;
}
const s1=newSlide('Response Windows End Before +500 ms',
  'Pixel event to the recorded hit or miss, 600 trials per participant',
  'Median duration: A 177 ms, B 220.5 ms. Peak searches stop at each trial’s outcome.',
  `After viewing the velocity traces, we checked how much of that plotting window actually falls within each trial's response window. The project defines the response-search interval from the Pixel event to the Got target or Missed target event. Both hits and misses remain in this check.

This chart groups the duration of that interval into 100 ms bins. Each participant contributes 600 trials. Participant A has a median duration of 177 ms and Participant B has a median of 220.5 ms. The full dataset ranges from 31 to 449 ms, so every trial ends before +500 ms.

This matters for the earlier velocity plot. Its later samples are useful context, but many occur after the target outcome. An onset analysis that searches the entire fixed window could select a later movement instead of the response of interest. We therefore search for peaks only within each trial's own event window and mark its endpoint on example plots.

This is a descriptive timing difference, not evidence that one participant has a later corrective onset. The average at a late time can also contain a different subset of trials because shorter trials have ended.

Source: 02_exploratory_analysis.qmd, “Quality, retention, and event timing” and “All participants, conditions, speeds, and blocks.” Numeric source: eda_output/trial_quality_audit.csv, End_ms, all 1,200 trials. Bin intervals are [0,100), [100,200), [200,300), [300,400), [400,500) ms.`,0);
formatChart(s1.charts.add('bar',{
  position:chartFrame,categories:data.duration_bins,
  series:['Participant A','Participant B'].map((name,i)=>({name,
    values:data.durations.filter(r=>r.Participant===name).map(r=>r.Fraction),fill:i?C.orange:C.blue})),
  barOptions:{direction:'column',grouping:'clustered',gapWidth:95},
  hasLegend:true,legend:{position:'bottom',overlay:false,textStyle},
  xAxis:{title:{text:'Time after Pixel event (ms)',textStyle},textStyle,majorGridlines:null},
  yAxis:{min:0,max:.7,majorUnit:.1,numberFormatCode:'0%',textStyle,
    majorGridlines:{fill:'#DAE1E6',width:.7}},
  dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'0.0%',textStyle:{fontSize:16,fill:C.ink}},
  chartFill:'#FFFFFF',plotAreaFill:'#FFFFFF',chartLine:{fill:'none',width:0}
}));

const s2=newSlide('Pre-event Fluctuations Exceed the Thresholds',
  'Median trial SD from −200 to −20 ms before the Pixel event',
  'Baseline SD is about 2.4–2.5 m/s². The prescribed thresholds are 0.20 and 0.125 m/s².',
  `Next, we quantified the pre-event acceleration fluctuations instead of relying only on how noisy the curves look. For each trial, we calculated the standard deviation of unsmoothed position-derived acceleration from -200 to -20 ms relative to the Pixel event. The four blue bars show the median of those trial-level SD values within each participant and condition, pooling backgrounds, target speeds, and blocks. Each group has 300 trials.

The medians are ${data.baseline.map(r=>`${r.Participant}, Condition ${r.Condition}: ${r.Median_SD.toFixed(2)} m/s²`).join('; ')}. The two smaller bars show the magnitudes of the project thresholds: 0.20 m/s² for ordinary GMR and 0.125 m/s² for threshold alignment. These are threshold magnitudes, not additional estimates of baseline SD.

The baseline is part of an ongoing reaching movement, so its variability includes actual movement as well as measurement or differentiation noise. This comparison does not prove that the thresholds are wrong. It shows why a single excursion above threshold cannot by itself establish corrective onset, especially in an unsmoothed signal. The median trial spends about ${(data.baseline_fraction_all*100).toFixed(1)}% of its baseline samples outside ±0.20 m/s². This is a descriptive amplitude check, not a false-positive onset rate.

We also checked whether differentiation or importing the data caused the discrepancy. Twice-differentiated position closely reproduces the supplied acceleration, with a maximum trial RMSE below 9 × 10^-12 m/s² in these data. Thus, the noisy signal is not explained by a simple mismatch between those acceleration sources.

Before estimating onset, we need to confirm the left/right response signs and evaluate any filtering choice. The project method works backward from the relevant positive response peak to the last upward crossing. We have not reported onset results here.

Source: 02_exploratory_analysis.qmd, “Validate position-derived acceleration” and “Baseline noise, polarity, and threshold feasibility.” Numeric sources: eda_output/trial_features.csv, Baseline_SD and Fraction_outside_020, and eda_output/signal_agreement.csv, RMSE.`,1);
const values=data.baseline.map(r=>r.Median_SD).concat([.20,.125]);
formatChart(s2.charts.add('bar',{
  position:chartFrame,
  categories:['A: Condition A','A: Condition B','B: Condition A','B: Condition B','GMR threshold','Alignment threshold'],
  series:[{name:'Magnitude (m/s²)',values,fill:C.blue,points:[
    {idx:4,fill:C.orange},{idx:5,fill:C.gray}]}],
  barOptions:{direction:'column',grouping:'clustered',gapWidth:100},hasLegend:false,
  xAxis:{textStyle:{...textStyle,fontSize:16.5},majorGridlines:null},
  yAxis:{title:{text:'Acceleration magnitude (m/s²)',textStyle},min:0,max:3,majorUnit:1,
    numberFormatCode:'0.0',textStyle,majorGridlines:{fill:'#DAE1E6',width:.7}},
  dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'0.000',textStyle:{fontSize:17.33,fill:C.ink}},
  chartFill:'#FFFFFF',plotAreaFill:'#FFFFFF',chartLine:{fill:'none',width:0}
}));

const noise=data.example_noise;
const s3=newSlide('Smoothing Changes the Acceleration Signal',
  'Participant A, Condition A, Block 1, Trial 12. Left background and slow target.',
  'Smoothing reduces fluctuations and can move threshold crossings. Filter choice remains open.',
  `Finally, we explored how sensitive acceleration is to preprocessing. This is one recorded left-background, slow-target trial from Participant A, Condition A, Block 1, Trial 12. The Pixel event occurs at time zero and the recorded miss ends its response-search window ${data.sample_end} ms later. Negative times show pre-event context only. The vertical dotted line marks the Pixel event.

All three curves start with the same hand-position data. The gray curve differentiates raw position twice. The blue and orange curves first apply centered moving averages to position over 11 ms or 21 ms, then differentiate twice using 1 ms sampling. These are example windows from the Quarto sensitivity analysis, not recommended filters.

The example's pre-event acceleration SD changes from ${noise[0].Baseline_SD.toFixed(2)} m/s² without smoothing to ${noise[1].Baseline_SD.toFixed(3)} m/s² with the 11 ms position window and ${noise[2].Baseline_SD.toFixed(3)} m/s² with the 21 ms window. All curves use the same vertical scale so the audience can see the magnitude of the change. The smoother curves lie close to zero on that scale.

A smoother curve does not automatically give a more accurate onset. A centered average can spread post-event information backward, and either window can change peak location and threshold crossing. This example illustrates sensitivity only. It is not an onset estimate and should not be generalized from a single trial.

The next step is to confirm the response-direction mapping, document an appropriate preprocessing choice, and examine whether both GMR methods give stable results across reasonable settings. Static or none trials should remain descriptive controls rather than entering onset estimates once that mapping is confirmed.

Source: 02_exploratory_analysis.qmd, “Smoothing sensitivity on a balanced set of example trials.” Data: ${data.sample_file}. Centered position windows 1, 11, and 21 samples at 1,000 Hz, followed by two centered numerical derivatives. No smoothing settings were chosen from this example.`,2);
const raw=data.traces.filter(r=>r.Width_ms===1);
const maxAbs=Math.max(...raw.map(r=>Math.abs(r.Acceleration)));
const limit=Math.ceil(maxAbs/2)*2;
const colors=['#AAB6C0',C.blue,C.orange];
const series=[1,11,21].map((width,i)=>({name:width===1?'No smoothing':`${width} ms position window`,
  xValues:data.traces.filter(r=>r.Width_ms===width).map(r=>r.Time_ms),
  values:data.traces.filter(r=>r.Width_ms===width).map(r=>r.Acceleration),
  line:{fill:colors[i],width:i===0?1:2,style:'solid'},marker:{symbol:'none'}}));
series.push({name:'Pixel event',xValues:[0,0],values:[-limit,limit],
  line:{fill:'#526C84',width:1,style:'dotted'},marker:{symbol:'none'}});
formatChart(s3.charts.add('scatter',{
  position:chartFrame,series,scatterOptions:{style:'line'},hasLegend:true,
  legend:{position:'bottom',overlay:false,textStyle:{...textStyle,fontSize:17.33}},
  xAxis:{title:{text:'Time after Pixel event (ms)',textStyle},min:-200,max:100,majorUnit:50,
    crossesAt:-limit,position:'bottom',tickLabelPosition:'low',
    textStyle,numberFormatCode:'0',majorGridlines:null},
  yAxis:{title:{text:'Acceleration (m/s²)',textStyle},min:-limit,max:limit,majorUnit:limit/2,
    crossesAt:-200,position:'left',tickLabelPosition:'low',
    textStyle,numberFormatCode:'0',majorGridlines:{fill:'#DAE1E6',width:.7}},
  chartFill:'#FFFFFF',plotAreaFill:'#FFFFFF',chartLine:{fill:'none',width:0}
}));

await fs.mkdir('.slide_build/draft',{recursive:true});
await (await PresentationFile.exportPptx(p)).save('.slide_build/draft/extended-artifact.pptx');
for(let i=0;i<p.slides.items.length;i++){
  const blob=await p.export({slide:p.slides.items[i],format:'png',scale:1});
  await fs.writeFile(`.slide_build/draft/slide-${i+1}.png`,new Uint8Array(await blob.arrayBuffer()));
}
await fs.writeFile('.slide_build/draft/inspection.ndjson',(await p.inspect({kind:'slide,textbox,chart,notes',maxChars:100000})).ndjson);
console.log('Authored',p.slides.items.length,'slides, including three additions with notes.');
