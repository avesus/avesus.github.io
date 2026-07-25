I strive to tackle all of these problems at once via subsidiaries:

The same customer industry may appear under multiple subsidiaries because each attacks a different layer. A robotics company, for example, may suffer an authority problem belonging to subsidiary 1, a computational-structure problem belonging to subsidiary 2, and an interface-apparatus problem belonging to subsidiary 3.

Below, read every bullet as beginning with “Of course…”

1. Capability-native agency

What the subsidiary is oriented around: systems in which AI agents and autonomous machines possess structurally bounded authority, rather than ambient power constrained by monitoring, policies, and retrospective accountability.

Segment 1A: Enterprise AI agents acting across production systems

* An agent must use a human account, service account, API key, or application identity to act.
* The account receives the union of every permission the agent might need during any possible task.
* Permissions remain the same when the agent’s purpose, principal, instructions, state, or environment changes.
* Authority is described as API operations rather than the real-world consequence being authorized.
* An agent authorized to perform one task can technically exercise the same permissions for unrelated reasons.
* Every external system maintains a separate and incompatible conception of what the agent may do.
* The agent’s effective authority can only be reconstructed by combining credentials, roles, tool definitions, application policies, and network access.
* An organization cannot ask one system to enumerate everything a particular agent can currently cause.
* Untrusted instructions and documents enter the same reasoning process that controls consequential tools.
* Prompt-injection defense is expected to determine whether information is legitimate instead of structurally limiting what influenced behavior can cause.
* Tool wrappers describe callable operations but do not own the state or consequences affected by those operations.
* Long-running tasks retain authority even after the human’s reason for delegating it has disappeared.
* Changing the model, prompt, planning method, or toolchain does not trigger reconsideration of the authority already granted.
* The same authenticated agent may behave completely differently after an invisible vendor update.
* Human approval is inserted at arbitrary checkpoints even when the approver cannot reconstruct the agent’s state or downstream plan.
* Safety is treated as a choice between approving every action and granting enough ambient power for the agent to be useful.
* Audit logs are accepted as the answer to actions that should sometimes have been impossible.
* Rollback is treated as sufficient even for disclosures, payments, commitments, communications, and other irreversible consequences.
* Responsibility remains assigned to a human who may have neither understood nor controlled the action that occurred.
* Increasing agent usefulness necessarily means increasing the amount of institutional power exposed to uncertain behavior.

Segment 1B: Multi-agent systems and delegated machine organizations

* Delegating authority means transmitting a credential, token, session, or proxy relationship.
* Delegated power does not naturally become narrower as it moves through a chain of agents.
* The recipient learns what operation it can perform but not the complete provenance and purpose of the authority.
* Agents coordinate through messages while ownership of the state being changed remains external and implicit.
* Several agents may concurrently act on the same consequential state without any one of them owning its mutation.
* Agent identity, process identity, model identity, session identity, and organizational responsibility collapse into one vague actor.
* An agent cannot create a subordinate agent whose possible effects are structurally and inspectably contained within its own authority.
* Revoking one delegation requires discovering all credentials, sessions, queues, derived tasks, and downstream delegations created from it.
* Authority expiration is expressed through time limits rather than completion, withdrawal, state change, or disappearance of purpose.
* A coordinator must possess broader power than every activity it coordinates.
* Cross-agent safety depends on global policy and monitoring possessing a complete view of the organization.
* An agent may correctly complete its local assignment while violating the intent governing the larger undertaking.
* Conflicts between agents are settled by priorities, retries, locks, or human intervention rather than explicit ownership relationships.
* Organizational boundaries are represented by service endpoints rather than by the structure of the computation itself.
* A failure in one agent can leave partially executed authority distributed across other agents and external systems.
* A complete causal history of who authorized what is difficult precisely when delegation becomes economically useful.

Segment 1C: Autonomous industrial and robotic action

* Authentication of a controller or operator is treated as authorization for the physical commands it emits.
* A planner receives control of an entire machine because actuators cannot possess narrower purpose-specific authority.
* Safety limits constrain speeds, forces, zones, and modes without expressing which actor owns which physical consequence.
* A legitimate high-level objective is assumed to legitimize every intermediate action selected to achieve it.
* Local machine components cannot possess and delegate authority over their own state and physical territory.
* A central controller must own the powers of every subsystem it coordinates.
* Maintenance credentials grant broad control because precise temporary authority is harder to express.
* Remote support requires opening general access to machines whose physical context the remote party cannot observe completely.
* Disconnected operation requires either stopping the machine or continuing with authority that may have become obsolete.
* Physical state changes faster than centrally administered permissions can be reconsidered.
* Safety relies on cages, interlocks, emergency stops, monitoring, and shutdown after the acting computation has already received power.
* A machine cannot prove locally that a requested action falls inside the exact authority delegated for its present state.
* Changing machine configuration invalidates assumptions embedded in separate access-control and safety systems.
* Human operators remain legally responsible for autonomous actions whose selection mechanism they cannot inspect.
* More autonomous physical operation is presumed to require more centralized surveillance and override power.

Segment 1D: Capability-enforced computing infrastructure

* Authority belongs to identities and roles rather than being a first-class structural possession.
* An application starts with ambient access to its process, filesystem, network, environment, and inherited services.
* Isolation follows machines, containers, accounts, and processes rather than semantic state ownership.
* Tenant separation is imposed around applications that were internally designed with ambient power.
* Security policy is evaluated outside the mechanism whose behavior it constrains.
* Passing an authorization check creates ambient authority inside the authorized component.
* A service must trust upstream callers to use its operations for legitimate purposes.
* Composing two individually permitted services can create an unanticipated combined authority.
* Periodic access reviews substitute for continuous knowledge of live delegation relationships.
* Permissions accumulate because removing one may break an undocumented dependency.
* Revocation is coarse because authority was never represented as a specific relationship.
* Central policy machinery must understand an increasingly distributed and dynamic system.
* Compromise containment follows administrative boundaries rather than the causal structure of the affected operation.
* Security evidence consists of configurations, logs, scans, and policy reports rather than an inspectable limit on possible effects.
* Owners of information and processes cannot directly own the computational territory through which their authority is exercised.

2. Live reconfigurable physical computation

What the subsidiary is oriented around: spatial, locally owned, dynamically reconfigurable computation for instruments, robots, satellites, industrial systems, adaptive edge machines, and eventually programmable matter.

Segment 2A: Scientific and technical instruments

* The instrument’s computational structure is fixed when its electronics are designed.
* New measurement behavior must be forced through signal paths created for earlier assumptions.
* A physically local event must travel to a designated processor before it can participate in computation.
* Signal acquisition, processing, control, storage, visualization, and physical response live in separate subsystems.
* Adding a new interpretation generally means adding software above the existing data pipeline rather than changing the pipeline’s causal structure.
* Instrument state is divided among firmware, host software, configuration files, calibration databases, and operator procedures.
* The instrument’s displayed state is not the same object as the state governing its physical behavior.
* Multiple instruments must be synchronized by clocks, triggers, cables, timestamps, and post-processing.
* A new experiment requires humans to reconstruct causality across instruments that cannot own a shared computational region.
* Calibration is a separate procedure rather than an evolving part of live computation.
* An instrument may expose data while concealing the mechanism that transformed observation into result.
* Field updates replace firmware images rather than alter bounded live regions.
* One changed component can require requalification of the entire measurement chain.
* Diagnosing a transient failure requires correlating logs and captures created by different clocks.
* Flexibility is purchased by transferring more responsibility to a host computer and more integration work to the operator.

Segment 2B: Industrial systems and robots

* Sensors and actuators are endpoints attached to a central controller rather than computational participants in their local physical territory.
* Production machinery must stop while its computational structure is changed.
* Reconfiguration is performed by specialists using representations separate from the live machine.
* A physical rearrangement requires corresponding changes to addressing, routing, configuration, safety, calibration, and software.
* The machine cannot discover a changed structure and reorganize its causal ownership locally.
* Coordination among nearby components requires communication through a central controller or network.
* Locality is treated as a latency optimization rather than part of the machine’s semantics.
* Machine state is scattered among controllers, drives, robots, databases, supervisory software, and undocumented operator knowledge.
* Adding one machine or station becomes a system-integration project.
* A local failure disables a large functional region because failure boundaries follow equipment boundaries.
* Redundancy duplicates large components because smaller computational territories cannot survive and reorganize independently.
* Real-time behavior is maintained through priorities, schedules, overprovisioning, and strict limits on change.
* Adaptability and deterministic operation are treated as conflicting objectives.
* Safety certification depends on freezing the architecture that changing operating conditions make obsolete.
* Operators observe alarms, traces, dashboards, and schematics rather than the live causal organization of the machine.
* A robot’s computational topology remains unrelated to the topology of the body and environment it controls.
* Machine lifetime greatly exceeds the lifetime of the computational assumptions and components embedded in it.

Segment 2C: Satellites and remote autonomous systems

* Computational architecture must be finalized years before the system encounters its operating environment.
* Post-deployment adaptability is restricted to behaviors anticipated before launch or installation.
* Reconfiguration means selecting among predesigned modes or uploading another externally prepared image.
* Every possible future need competes for fixed processing, routing, memory, and redundancy decided in advance.
* Reliability requires duplicating complete subsystems rather than allowing surviving regions to reorganize.
* A damaged region cannot naturally transfer its state, function, and authority to neighboring resources.
* Communication delay requires local autonomy while authority and planning remain centered on remote operators.
* Loss of communication forces a choice between inactivity and continued operation under outdated assumptions.
* Repurposing healthy physical hardware is considered too risky because computational structure cannot change transparently.
* Verification evidence applies to a static configuration and becomes uncertain after meaningful reconfiguration.
* State transition, resource ownership, physical location, and communication topology are maintained in separate representations.
* Remote operators reconstruct causality from sparse telemetry rather than inspect the computation itself.
* Scarce energy is consumed moving data among fixed resources because computation cannot migrate into the relevant physical locality.
* Mission lifetime is constrained by the obsolescence of inaccessible computational components.
* Hardware that physically survives cannot acquire fundamentally new organization without having been designed for that exact possibility.

Segment 2D: Adaptive edge machines

* “Edge computation” means placing a conventional fixed computer nearer to the phenomenon.
* The device remains architecturally centralized even when geographically decentralized.
* Sensors convert local physical behavior into data that must travel through buses, memory, schedulers, and processing cores.
* Accelerated functions remain fixed structures selected before the device’s future workload is known.
* Updating behavior changes instructions while the causal machinery executing those instructions remains fixed.
* Reconfigurable resources are controlled through externally compiled configurations rather than live local ownership.
* Changing one computational region safely requires reasoning about hidden global timing, routing, and resource effects.
* Storage, communication, and computation remain separate systems even when all are physically adjacent.
* Workloads compete through a scheduler that understands resources but not the physical meaning of their work.
* Local state ownership is represented in software conventions rather than physical computational boundaries.
* Power and latency are optimized after data movement and abstraction have already been accepted.
* More adaptability requires a larger operating stack and therefore more opacity and failure surface.
* Determinism requires bypassing the flexible layers that were added to make the device adaptable.
* Device behavior cannot grow a new bounded computational structure in response to its physical experience.
* Inspecting the running machine reveals processors and tasks, not the spatial causal organization of its behavior.

Segment 2E: Programmable matter and large spatial electronics

* Physical modules require fixed identifiers assigned independently of their current physical relationships.
* Global software must reconstruct topology before useful collective behavior can begin.
* Regular manufactured geometry is assumed even when the material is cut, damaged, folded, extended, or assembled irregularly.
* Physical adjacency, communication adjacency, computational ownership, and mechanical attachment remain different relationships.
* Power and data distribution must be designed before the final spatial behavior is known.
* Central coordination becomes more complex with every additional module.
* Local interaction rules may produce demonstrations, but useful machinery is presumed to require a global plan.
* Shape change and computation are treated as separate subsystems.
* A damaged module can break addressing, routing, synchronization, or power for otherwise healthy regions.
* Self-repair means restoring a preexisting configuration rather than reorganizing live function around changed matter.
* A region cannot naturally establish a boundary, own state, expose ports, and authorize local mutation.
* Cutting or combining physical material invalidates an externally maintained computational model.
* Connectors, wiring, addressing, and configuration dominate the scale at which modules can exist.
* Programmable matter is considered commercially irrelevant until it achieves science-fiction-like arbitrary shape transformation.
* Large spatial electronics remain either passive surfaces or centrally managed collections of conventional devices.
* The physical object and the computation governing it remain distinct things.

3. Minimal-apparatus physical intelligence

What the subsidiary is oriented around: near-sensor computation, direct physical interfaces, tiny local learning, unusual active devices, and systems that remove converters, centralized machinery, or inaccessible fabrication where those layers constitute the real burden.

Segment 3A: Near-sensor computation and distributed sensing

* A sensor’s job ends when it produces a standardized signal or number.
* The physical phenomenon must be conditioned, digitized, buffered, timestamped, transported, stored, and interpreted elsewhere.
* All potentially available information should be preserved even when the required local decision is simple.
* Raw observations must travel because sensing and meaning are institutionally separate functions.
* The data generated by sensing can cost more to transmit and store than the local consequence is worth.
* Each sensing point requires power regulation, conversion, clocks, firmware, addressing, protocols, and maintenance.
* “Near-sensor” intelligence still begins after conversion into conventional digital representation.
* The apparatus between phenomenon and decision may dominate the sensor itself.
* Sensors with slightly different physical behavior must be normalized through repeated calibration.
* Noise, hysteresis, nonlinear response, and material history are removed before computation rather than allowed to participate in it.
* A local threshold or control decision still inherits a general-purpose computational stack.
* Sensing networks are designed around central collection even when most collected data produces no action.
* Bandwidth and storage are expanded rather than questioning why the observation must leave its source.
* Failure of communication removes intelligence from an otherwise functioning physical sensor.
* Distributed sensing creates a permanent battery, maintenance, identity, synchronization, and software-management burden.

Segment 3B: Direct physical interfaces and converter-heavy systems

* Every distinct physical domain requires a chain of specialized conversion and interface components.
* A nearby physical cause and effect must communicate through standardized representations rather than direct computational relationships.
* A one-bit physical decision may require analog conditioning, conversion, processing, protocol handling, and output conversion.
* Interface architecture is selected for generality even when generality greatly exceeds the required function.
* Converter accuracy preserves distinctions irrelevant to the intended physical consequence.
* Timing created naturally by the physical mechanism is replaced by clocks, sampling, buffering, and reconstruction.
* Feedback loops leave the physical locality they regulate and return through multiple abstraction layers.
* Interfaces confirm that signals were transmitted without confirming that the intended physical result occurred.
* Every layer requires its own debugging instruments, models, expertise, and failure analysis.
* Interoperability means accepting the complete standardized stack used by every other participant.
* Direct coupling is dismissed as fragile or application-specific while the costs of universal abstraction are treated as unavoidable.
* Removing an interface layer is framed as component optimization rather than an opportunity to reconceive the causal system.
* Physical devices become dependent on drivers, firmware, and protocol support that may disappear before the device wears out.
* The ownership of the physical effect and the ownership of the machinery producing it remain separate.

Segment 3C: Tiny local learning and adaptation

* Learning happens in centralized infrastructure while deployed devices merely execute inference.
* A machine must export its experience before it may improve from that experience.
* Training and operation are separate lifecycle phases.
* Adaptation means replacing the deployed model from elsewhere.
* A small learning system is designed by compressing an architecture created for vastly larger machinery.
* Model size is treated as the primary path to capability.
* Device-specific learning is considered too expensive to maintain independently.
* Fleet-wide averaging is preferable even when it erases important local physical differences.
* Local examples require human labeling before they can become useful learning material.
* Learning state, operational state, sensor history, and control state remain separate.
* Continual learning is prohibited because the mechanism of change cannot be observed or bounded.
* An offline device is expected to remain intellectually frozen.
* Local uncertainty is represented as a number rather than embodied in what the machine may safely do.
* Memory, arithmetic, communication, and sensing remain separate costs inside even the smallest adaptive system.
* Energy, latency, and physical realization are addressed after the learning mechanism has been chosen.
* Learning success is measured by abstract benchmark accuracy rather than improved physical behavior.
* Understanding how a tiny system changed is considered no easier than interpreting a remote statistical model.
* Local adaptation requires trusting the vendor’s update infrastructure rather than the owner’s observable mechanism.

Segment 3D: Unusual active devices and accessible fabrication

* Useful active computation requires semiconductor junctions manufactured through inaccessible fabrication infrastructure.
* Creating active function and creating interconnect are fundamentally different manufacturing activities.
* A circuit board may route intelligence but may not itself embody the active mechanism.
* Small organizations may assemble purchased intelligence but cannot manufacture consequential active behavior.
* Magnetic materials belong in transformers, inductors, storage, or sensing—not general switching and gain.
* Material hysteresis and nonlinear response are nuisances to characterize away rather than possible computational mechanisms.
* Alternative devices must outperform conventional transistors generally before being considered useful in any neglected niche.
* Small-run custom active devices are economically impossible.
* Device geometry cannot become an ordinarily machinable file in the way mechanical parts and circuit boards can.
* Fabrication knowledge belongs to specialized institutions rather than to the people designing systems.
* Makers and ordinary laboratories are allowed to construct passive arrangements around sealed active components.
* Local fabrication of active function is educational demonstration rather than serious production.
* Repair means replacing a proprietary active component rather than reproducing its mechanism.
* One discontinued component can permanently disable an otherwise repairable machine.
* Supply-chain concentration is treated as an intrinsic property of electronics.
* Harsh physical environments require expensive specialized versions of the same inaccessible technology.
* Material and process variation prevent computation rather than becoming usable state.
* The scale of fabrication capital determines who is permitted to invent new computational matter.
* Computation is assumed to be permanently coupled to transistor economics, semiconductor geopolitics, and centralized manufacturing.
