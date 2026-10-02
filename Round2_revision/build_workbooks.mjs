import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';
const O=path.dirname(fileURLToPath(import.meta.url));
const data=JSON.parse(await fs.readFile(path.join(O,'audit','workbook_data.json'),'utf8'));
const closure=JSON.parse(await fs.readFile(path.join(O,'audit','closure_workbook_data.json'),'utf8'));
const qa=path.join(O,'audit','workbook_previews');await fs.mkdir(qa,{recursive:true});
function col(n){let s='';for(n++;n;n=Math.floor((n-1)/26))s=String.fromCharCode(65+(n-1)%26)+s;return s;}
const readme={headers:['Item','Meaning'],rows:[
 ['Authority','Certified R2.2 simulations only; original and preliminary outputs preserved separately.'],
 ['Principal experiment','90 days x corrected V2H/V2G, reserve capped at 3 kWh; none and >= initial EV terminal energy.'],
 ['Equality sensitivity','21 attempted paired days; failed cases explicitly retained and diagnosed.'],
 ['Dates','Explicit workbook Day/Month/Year, not Excel conversion of DayNum. Baseline 2014-06-19.'],
 ['Cost unit','GBP per 24-hour solved horizon. Negative cost means net operating revenue, not investment profitability.'],
 ['Saving','Corrected V2H cost minus V2G cost. Positive threshold GBP 0.00001; ties within tolerance.'],
 ['Restoration A/B','Symmetric post-optimisation accounting. B is a next-day EV-only charging subproblem, not full-household feasibility.'],
 ['Restoration C','True 24-hour household re-optimisation with EV final energy >= initial energy. No rolling horizon.'],
 ['Accuracy','Principal: absolute gap 1e-8 GBP. Tariff scan: up to 0.005 GBP; tighten ambiguous signs to 1e-8. Both final bracket signs certified.'],
 ['Missing values','Blank numerical cells for failed/unavailable quantities are not zero. Consult solver status and failure evidence.'],
 ['Scope','Single prepared household; no feeder, transformer, voltage, phase imbalance or hosting-capacity evidence.'],
 ['Integration','Source DOCX unchanged. Manuscript integration and public repository/licence approval remain open.'],
 ['Source','MATLAB finalise_round2.m and summarise_round2.py; exact case MAT paths in data tabs.'] ]};
async function build(filename,specs){
 const w=Workbook.create();
 const sheets=[['ReadMe',readme],...specs];
 for(const [name,d] of sheets){
  const sh=w.worksheets.add(name);sh.showGridLines=false;
  const n=d.rows.length+1,m=d.headers.length;
  sh.getRange(`A1:${col(m-1)}${n}`).values=[d.headers,...d.rows];
  const whole=sh.getRange(`A1:${col(m-1)}${n}`);
  whole.format.font={name:'Arial',size:10,color:'#222222'};
  whole.format.verticalAlignment='center';whole.format.rowHeight=22;
  const head=sh.getRange(`A1:${col(m-1)}1`);
  head.format={fill:'#304F46',font:{name:'Arial',size:10,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:48};
  head.format.horizontalAlignment='center';
  for(let j=0;j<m;j++){
   const key=d.headers[j];const rg=sh.getRange(`${col(j)}2:${col(j)}${n}`);
   let width=20;
   if(key==='SampledVariable')width=32;
   if(/CaseID|Comparison|Check|Interpretation|Meaning|Result|Required|evidence|implementation|action|location|change|performed/i.test(key))width=42;
   if(/SourceMAT/.test(key))width=66;
   sh.getRange(`${col(j)}1:${col(j)}${n}`).format.columnWidth=width;
   const numeric=d.rows.some(r=>typeof r[j]==='number');
   if(numeric){
    rg.format.horizontalAlignment='right';
    const fractional=d.rows.some(r=>typeof r[j]==='number'&&!Number.isInteger(r[j]));
    rg.setNumberFormat(/Residual|Error|Gap|Balance|Tolerance|MaxObserved/.test(key)?'0.000E+00':/GBP|kWh|kW|_s|_h|pct|Scale|Tariff|Percent/.test(key)||fractional?'0.000000':'0');
   }
   else {rg.format.horizontalAlignment='left';rg.format.wrapText=true;}
   if(/Pass|Status|Valid/.test(key))rg.conditionalFormats.add('containsText',{text:'NOT CLOSED',format:{fill:'#FCE8E6',font:{bold:true,color:'#9F2922'}}});
  }
  if(name==='ReadMe'){sh.getRange(`B1:B${n}`).format.columnWidth=110;whole.format.rowHeight=36;sh.tabColor='#8B9692';}
  else {sh.freezePanes.freezeRows(1);if(n>25)sh.freezePanes.freezeColumns(2);}
  if(name==='Closure'){whole.format.rowHeight=130;head.format.rowHeight=48;}
  if(name==='Summary'){sh.tabColor='#304F46';}
  sh.tables.add(`A1:${col(m-1)}${n}`,true,`T_${name.replace(/[^A-Za-z0-9]/g,'_')}`);
 }
 w.recalculate();
 const check=await w.inspect({kind:'region',sheetId:specs[0][0],range:'A1:F8',maxChars:2500});
 await fs.writeFile(path.join(qa,filename+'.inspection.json'),JSON.stringify(check,null,2));
 for(const [name,d] of sheets){
  const p=await w.render({sheetName:name,range:`A1:${col(Math.min(d.headers.length,6)-1)}${Math.min(d.rows.length+1,9)}`,scale:1,format:'png'});
  await fs.writeFile(path.join(qa,filename+'_'+name+'.png'),new Uint8Array(await p.arrayBuffer()));
 }
 const x=await SpreadsheetFile.exportXlsx(w);await x.save(path.join(O,filename));
 console.log(filename,'exported',sheets.length,'sheets');
}
await build('Round2_Final_Results.xlsx',[
 ['Summary',data.comparison_summary],['Paired days',data.principal_pairs],['Baseline',data.baseline_runs],
 ['Runtime',data.computational_summary],['Saving materiality',data.saving_materiality],['Restoration summary',data.restoration_summary],
 ['Restoration regimes',data.restoration_day_level],['Restoration paired',data.restoration_paired],
 ['Tariff thresholds',data.break_even_thresholds],['Tariff pairs',data.tariff_pairs],
 ['Subset profiles',data.subset_profile_comparison],['Separate correction effects',data.separated_accuracy_and_reserve_effects],
 ['All principal attempts',data.certified_principal_runs]]);
await build('Round2_Validation_Report.xlsx',[
 ['Summary',data.validation_summary],['Check counts',data.validation_check_counts],
 ['Equality failures',data.equality_infeasibility_evidence],['Model counts reserve',data.model_counts_reserve],
 ['MC audit only',data.monte_carlo_variable_trace]]);
await build('Round2_Reviewer_Closure_Matrix.xlsx',[['Closure',closure]]);
