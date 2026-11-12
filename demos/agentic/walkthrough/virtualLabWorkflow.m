%[text] # Choose the next experiment with a virtual lab
%[text] This scripted workflow uses the same SimBiology experiment engine and MATLAB planner as the interactive app. It runs independently of Claude. Every measurement here is simulated; the biological model is illustrative and uncalibrated.
setupVirtualLab()
session = virtuallab.newSession();
%[text] Eight initial conditions provide paired fluorescence and growth observations. The budget allows twelve additional conditions. Fluorescence is mature-reporter concentration divided by 1 nM, in arbitrary units. Relative growth is the endpoint specific growth rate divided by its unburdened reference value at eight hours.
session.Observations
%%
%[text] ## Recommend experiments from the evidence available
%[text] Separate Gaussian-process models predict fluorescence and growth from the measured conditions. Constrained expected improvement balances a higher signal against the probability of satisfying the growth requirement. A diversity penalty spreads each batch. The selector does not inspect unmeasured simulation outputs.
[session,firstProposal] = virtuallab.propose(session);
firstProposal(:,["CandidateID","PromoterStrength","InducerMicromolar","FluorescenceMean","GrowthMean","FeasibilityProbability"])
plotVirtualLabState(session)
%%
%[text] ## Measure the proposed conditions with SimBiology
%[text] Each condition runs transcription, translation, reporter maturation, turnover, and growth-dependent dilution in one model. The same simulated condition supplies both readouts. Only completed measurements consume the experiment budget.
session = virtuallab.runBatch(session);
session.Observations
plotVirtualLabState(session)
%%
%[text] ## Tighten the requirement without losing measurements
%[text] Compare recommendations at 80% and 90% using the same observation set. Changing the requirement invalidates the pending proposal but preserves measured outcomes and the remaining budget. A predicted feasible condition can still fail the target when measured.
[session,proposalAt80] = virtuallab.propose(session);
session = virtuallab.setConstraint(session,0.90);
[session,proposalAt90] = virtuallab.propose(session);
comparison = table(proposalAt80.CandidateID,proposalAt90.CandidateID,VariableNames=["ProposedAt80Percent","ProposedAt90Percent"]);
disp(comparison)
plotVirtualLabState(session)
%%
%[text] ## Complete the budgeted study
%[text] Execute the revised batch and one final batch. The completed study contains the eight starting conditions plus twelve new conditions. The event history also records the proposal discarded when the requirement changed.
session = virtuallab.runBatch(session);
[session,finalProposal] = virtuallab.propose(session);
disp(finalProposal)
session = virtuallab.runBatch(session);
plotVirtualLabState(session)
session.Events
%%
%[text] ## Preserve the evidence and inspect the model
%[text] Use **Export run** in the app or call `virtuallab.exportRun(session,folder)` with a destination folder. The exported state and records preserve the seed, model version, observations, decisions, and budget for reproduction. Use **Open SimBiology model** to inspect the experiment engine.
%[text] The experiment planner is MATLAB code. An actual Claude connection can orchestrate these same actions using the prompts in the demo folder. This script is a reproducible workflow, not an agent-session recording. No claim of improved laboratory yield or fewer required laboratory experiments follows from these simulated results.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
