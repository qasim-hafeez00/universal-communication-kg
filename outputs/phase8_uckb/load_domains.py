"""
UCKB Phase 8 — Domain Node Loader
Loads Legal, Corporate, and Education domain nodes into Neo4j
using parameterized HTTP API calls (no quoting issues).

Usage:
    python load_domains.py
"""
import sys
import base64
import time

try:
    import requests
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
    import requests

sys.stdout.reconfigure(encoding="utf-8")

NEO4J_HTTP = "http://localhost:7474/db/neo4j/tx/commit"
NEO4J_USER = "neo4j"
NEO4J_PASS = "uckb_admin_2024"
AUTH = base64.b64encode(f"{NEO4J_USER}:{NEO4J_PASS}".encode()).decode()
HEADERS = {"Content-Type": "application/json", "Authorization": f"Basic {AUTH}"}


def run(statements: list) -> list:
    """Execute a list of {statement, parameters} dicts."""
    body = {"statements": statements}
    r = requests.post(NEO4J_HTTP, json=body, headers=HEADERS, timeout=60)
    r.raise_for_status()
    data = r.json()
    errors = data.get("errors", [])
    if errors:
        for e in errors:
            print(f"  ! {e.get('code','')}: {str(e.get('message',''))[:120]}")
    return data.get("results", [])


def merge_technique(card: dict) -> dict:
    return {
        "statement": """
            MERGE (t:Technique:CommunicationTechnique {cardId: $cardId})
            SET t += $props
            SET t:Resource
        """,
        "parameters": {"cardId": card["id"], "props": {k: v for k, v in card.items() if k != "id"}}
    }


def merge_signal_marker(node: dict) -> dict:
    return {
        "statement": """
            MERGE (sm:SignalMarker {cardId: $cardId})
            SET sm += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def merge_statement_marker(node: dict) -> dict:
    return {
        "statement": """
            MERGE (sm:StatementMarker {cardId: $cardId})
            SET sm += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def merge_emotional_state(node: dict) -> dict:
    return {
        "statement": """
            MERGE (e:EmotionalState {cardId: $cardId})
            SET e += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def merge_domain_protocol(node: dict) -> dict:
    return {
        "statement": """
            MERGE (dp:DomainProtocol {cardId: $cardId})
            SET dp += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def merge_comm_style(node: dict) -> dict:
    return {
        "statement": """
            MERGE (cs:CommunicationStyle {cardId: $cardId})
            SET cs += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def merge_knowledge_state(node: dict) -> dict:
    return {
        "statement": """
            MERGE (ks:KnowledgeState {cardId: $cardId})
            SET ks += $props
        """,
        "parameters": {"cardId": node["id"], "props": {k: v for k, v in node.items() if k != "id"}}
    }


def add_relationship(from_id: str, rel_type: str, to_id: str, props: dict = None) -> dict:
    if props:
        return {
            "statement": f"""
                MATCH (a {{cardId: $fromId}})
                MATCH (b {{cardId: $toId}})
                MERGE (a)-[r:{rel_type}]->(b)
                SET r += $props
            """,
            "parameters": {"fromId": from_id, "toId": to_id, "props": props}
        }
    return {
        "statement": f"""
            MATCH (a {{cardId: $fromId}})
            MATCH (b {{cardId: $toId}})
            MERGE (a)-[:{rel_type}]->(b)
        """,
        "parameters": {"fromId": from_id, "toId": to_id}
    }


# ─────────────────────────────────────────────────────────────
# LEGAL & INVESTIGATIVE DOMAIN
# ─────────────────────────────────────────────────────────────

LEGAL_TECHNIQUES = [
    {"id":"legal_001_free_narrative_invitation","name":"Free Narrative Invitation","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992; Geiselman1985; PEACE2000","description":"Open-ended invitation to produce a free, uninterrupted first-person account of events in the interviewee's own words and sequence.","whenToUse":"Account phase of PEACE; immediately after rapport is established.","whenNotToUse":"Interviewee is in acute distress; medical attention takes priority.","steps":"Say: Tell me everything you remember, from the beginning, in your own words. Take all the time you need. Remain silent; do not interrupt.","successSignals":"Interviewee produces extended unprompted narrative; includes sensory detail.","failureSignals":"Interviewee stops prematurely; provides minimal response.","triggerSignals":"account_phase_active; rapport_established","contraindications":"Do not interrupt account phase with clarifying questions.","dialogueActLinks":"Open-Question; Acknowledge; Feedback-Positive"},
    {"id":"legal_002_cognitive_interview","name":"Cognitive Interview","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992; Geiselman1985; Memon1997","description":"Evidence-based memory retrieval technique combining mental context reinstatement, report-everything, temporal-order change, and perspective change.","whenToUse":"Witness or victim account is sparse; memory retrieval support needed.","whenNotToUse":"Acute PTSD re-experiencing triggered; false memory risk high.","steps":"1) Mental Reinstatement 2) Report Everything 3) Change Temporal Order 4) Change Perspective — use only as needed.","successSignals":"New details emerge; interviewee becomes more fluent.","failureSignals":"Interviewee confused or contradicts earlier account.","triggerSignals":"account_phase_active; sparse_initial_account","contraindications":"Do not use all four components simultaneously; sequence them.","dialogueActLinks":"Instruct; Open-Question; Clarify"},
    {"id":"legal_003_mental_reinstatement","name":"Mental Reinstatement of Context","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992","description":"Guides interviewee to mentally return to the physical and emotional context of the event to enhance episodic memory retrieval.","whenToUse":"Initial account is thin; memory retrieval inhibited by anxiety.","whenNotToUse":"Active flashback state; child witnesses under age 7.","steps":"Ask: Close your eyes if comfortable. Think about where you were. What could you see, hear, smell? What were you feeling?","successSignals":"Interviewee enters reflective state; produces richer detail.","triggerSignals":"sparse_initial_account; account_phase_active","contraindications":"Contraindicated when trauma re-experiencing is active.","dialogueActLinks":"Instruct; Guide"},
    {"id":"legal_004_report_everything","name":"Report Everything Instruction","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992; Geiselman1985","description":"Instructs the interviewee that all memories are relevant, including partial, uncertain, or seemingly trivial details.","whenToUse":"Before free narrative; after rapport established.","whenNotToUse":"Rapport not established; confabulation tendency present.","steps":"Say: Tell me everything, even if it seems trivial or you are not sure. Everything you remember could be important.","successSignals":"Interviewee begins including uncertain fragments and peripheral detail.","triggerSignals":"interviewee_filtering_visible; sparse_account","contraindications":"Do not use before rapport is established.","dialogueActLinks":"Instruct; Clarify"},
    {"id":"legal_005_change_temporal_order","name":"Change Temporal Order","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 3","cognitiveLoadProfile":"high-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992; Vrij2008","description":"Asks the interviewee to recall events in reverse chronological order, disrupting schema-based confabulation.","whenToUse":"Inconsistency in account suspected; rehearsed narrative indicated.","whenNotToUse":"Fragmented trauma narrative; child witnesses; cognitive impairment present.","steps":"After full account: Now tell me the same sequence, but start from [later point] and go backwards in time.","cognitiveLoadProfile":"high-load","contraindications":"Contraindicated when trauma fragmentation risk is active.","dialogueActLinks":"Instruct; Challenge"},
    {"id":"legal_006_change_perspective","name":"Change Perspective","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 3","cognitiveLoadProfile":"high-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Fisher1992; Memon1997","description":"Asks the interviewee to describe events from a different vantage point, expanding the retrieved detail set.","whenToUse":"Account lacks spatial detail; scene geometry is legally relevant.","whenNotToUse":"Suggestible witnesses; children; trauma-linked false memory risk.","steps":"After full account: If you had been standing where [other person] was, what would you have seen?","contraindications":"Contraindicated when false memory risk is high.","dialogueActLinks":"Instruct; Open-Question"},
    {"id":"legal_007_contradiction_challenge","name":"Contradiction Challenge","domain":"Legal & Investigative","peaceStep":"Evaluation","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Williamson1993","description":"Presents a specific factual contradiction between the account and established evidence, inviting explanation without accusation.","whenToUse":"Full account obtained; specific factual discrepancy identified.","whenNotToUse":"Account phase not complete; interviewee in acute distress.","steps":"Say: You mentioned X, but our records show Y. Can you help me understand that?","contraindications":"Must never be used during the account phase.","dialogueActLinks":"Clarify; Challenge; Request"},
    {"id":"legal_008_timeline_clarification","name":"Timeline Clarification","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 2","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000","description":"Systematically clarifies temporal sequences using open-ended questions to establish chronological coherence.","whenToUse":"Account has temporal gaps or unclear sequencing.","steps":"Ask: Before X happened, what were you doing? And just after X, what happened next?","contraindications":"Do not use leading questions to establish the timeline.","dialogueActLinks":"Clarify; Open-Question; Request"},
    {"id":"legal_009_open_ended_probe","name":"Open-Ended Probe","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Fisher1992","description":"Single open-ended follow-up question elaborating a specific aspect of the free narrative without suggesting content.","whenToUse":"Account phase; any point where elaboration is needed.","steps":"Use: Tell me more about... Describe... What happened then?","contraindications":"Never lead; never suggest; never compound.","dialogueActLinks":"Open-Question; Clarify"},
    {"id":"legal_010_minimal_encourager","name":"Minimal Encourager","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"lowest-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000","description":"Minimal non-leading verbal or non-verbal signal that encourages continuation of narrative.","whenToUse":"Throughout account phase to maintain narrative momentum.","steps":"Use: I see; Go on; OK; head nod; brief silence.","contraindications":"Never use in a way that sounds like evaluation or agreement.","dialogueActLinks":"Acknowledge; Feedback-Positive"},
    {"id":"legal_011_summary_and_confirm","name":"Summary and Confirm","domain":"Legal & Investigative","peaceStep":"Closure","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Williamson1993","description":"Interviewer summarises the account using the interviewee's own language, inviting correction and confirmation.","whenToUse":"Closure phase; after full account obtained.","steps":"Say: Let me summarise what you have told me... Is that accurate? Is there anything you want to change or add?","contraindications":"Do not paraphrase in a way that alters meaning.","dialogueActLinks":"Summary; Request; Confirm"},
    {"id":"legal_012_right_to_silence","name":"Right to Silence Acknowledgment","domain":"Legal & Investigative","peaceStep":"Engage and Explain","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PACE1984; Miranda1966; PEACE2000","description":"Explicit acknowledgment of the legal right to silence in clear non-coercive language before the interview begins.","whenToUse":"Before any formal interview; always when interviewee is detained.","steps":"Deliver formal caution verbatim per jurisdiction; confirm understanding in plain language.","contraindications":"Omitting this in custodial context is an absolute violation.","dialogueActLinks":"Inform; Instruct"},
    {"id":"legal_013_rapport_through_transparency","name":"Rapport Through Transparency","domain":"Legal & Investigative","peaceStep":"Engage and Explain","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Gudjonsson2003","description":"Builds interview rapport through honest explanation of the interview's purpose, process, and the interviewee's rights without any deceptive framing.","whenToUse":"Always; first technique in any PEACE interview.","whenNotToUse":"Never — transparency is non-optional in PEACE.","steps":"Explain: who you are; why the interview is happening; what will happen to information; what rights the person has; how long it will last.","contraindications":"Deception by the interviewer destroys this technique.","dialogueActLinks":"Inform; Instruct; Rapport"},
    {"id":"legal_014_non_accusatorial_statement","name":"Non-Accusatorial Statement","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 2","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Leo2008","description":"Presents factual discrepancies or evidential concerns in neutral, non-blaming language that invites explanation.","whenToUse":"Interviewee shows defensiveness; discrepancy needs clarification.","steps":"Say: There is something I would like to understand better. [Fact]. Can you help me understand that?","contraindications":"Never re-frame as accusation after delivering as neutral statement.","dialogueActLinks":"Inform; Clarify"},
    {"id":"legal_015_account_gap_exploration","name":"Account Gap Exploration","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000; Adams1996","description":"Identifies and non-accusatorially explores temporal or factual gaps in the free account.","whenToUse":"Temporal or factual gap identified in free account.","steps":"Say: You mentioned X and then Y. Tell me what happened between those two points.","contraindications":"Do not suggest what the gap contains.","dialogueActLinks":"Clarify; Open-Question"},
    {"id":"legal_016_closure_invitation","name":"Closure Invitation","domain":"Legal & Investigative","peaceStep":"Closure","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000","description":"Explicit invitation at end of PEACE closure phase for interviewee to add anything omitted or correct misstatements.","whenToUse":"End of PEACE closure phase; after summary confirmed.","steps":"Ask: Is there anything else you would like to add, change, or tell me that I have not asked about?","contraindications":"Do not use as a fishing prompt.","dialogueActLinks":"Open-Question; Invite"},
    {"id":"legal_017_neutral_tone_calibration","name":"Neutral Tone Calibration","domain":"Legal & Investigative","peaceStep":"Account","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"PEACE2000","description":"Active maintenance of interviewer vocal and linguistic neutrality preventing tone from signalling belief or disbelief.","whenToUse":"Throughout all PEACE phases except Preparation.","steps":"Monitor own tone; use neutral acknowledgements; avoid evaluative language.","contraindications":"Neutrality does not mean coldness; warm professional tone required.","dialogueActLinks":"Tone; Monitor"},
    {"id":"legal_contraindicated_reid","name":"Reid Technique (CONTRAINDICATED)","domain":"Legal & Investigative","peaceStep":"none","tier":"BLOCKED","cognitiveLoadProfile":"N/A","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","activationBlocked":True,"contraindication":"ABSOLUTE","description":"Confrontational accusation-based interrogation technique. NEVER to be used.","whenToUse":"NEVER","whenNotToUse":"ALWAYS — this node exists to make the block explicit and queryable, not to be activated.","rationale":"Leo 2008 (false confessions); Kassin 2012 (DNA exonerations); Gudjonsson 2003. Techniques include false evidence claims and psychological coercion.","sourceIds":"Leo2008; Kassin2012; Gudjonsson2003"},
]

LEGAL_STATEMENT_MARKERS = [
    {"id":"sa_001_verb_tense_shift","name":"Verb Tense Shift","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.65","linguisticMarker":"past-tense narrative interrupted by present-tense verb","signalMeaning":"Re-experiencing OR rehearsed construction of account.","sourceIds":"Adams1996; Sapir2000"},
    {"id":"sa_002_pronoun_change","name":"Pronoun Change","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.60","linguisticMarker":"I to we pronoun shift without referent introduction","signalMeaning":"Distancing from personal ownership.","sourceIds":"Adams1996; Sapir2000"},
    {"id":"sa_003_missing_sequence","name":"Missing Sequence","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.70","linguisticMarker":"and then later; the next thing I remember","signalMeaning":"Omission around legally relevant period.","sourceIds":"Adams1996"},
    {"id":"sa_004_temporal_equivocation","name":"Temporal Equivocation","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.55","linguisticMarker":"about that time; around then","signalMeaning":"Avoidance of precise temporal commitment.","sourceIds":"Sapir2000; Adams1996"},
    {"id":"sa_005_lack_of_conviction","name":"Lack of Conviction","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.60","linguisticMarker":"I think I; I believe I applied to own actions","signalMeaning":"Reduced certainty about own acts.","sourceIds":"Adams1996; Sapir2000"},
    {"id":"sa_006_spontaneous_negation","name":"Spontaneous Negation","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.72","linguisticMarker":"I did not [crime] stated without being asked","signalMeaning":"High-confidence deception marker.","sourceIds":"Sapir2000; Vrij2008"},
    {"id":"sa_007_non_answer_answer","name":"Non-Answer Answer","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.65","linguisticMarker":"What I can tell you is; answers different question","signalMeaning":"Topic avoidance behavior.","sourceIds":"Adams1996"},
    {"id":"sa_008_involuntary_detail","name":"Involuntary Detail","domain":"Legal & Investigative","classLabel":"StatementMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.50","linguisticMarker":"unprompted specific detail on irrelevant element","signalMeaning":"Displacement behavior.","sourceIds":"Adams1996; Sapir2000"},
]

LEGAL_SIGNAL_MARKERS = [
    {"id":"legal_sig_memory_retrieval","name":"Memory Retrieval Signal","domain":"Legal & Investigative","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral","modality":"video;voice","confidenceThreshold":"0.75","description":"Interviewee enters visible reflective state indicating active episodic memory access."},
    {"id":"legal_sig_continued_narrative","name":"Continued Narrative Signal","domain":"Legal & Investigative","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.80","description":"Interviewee continues unprompted elaboration of account."},
    {"id":"legal_sig_account_completed","name":"Account Completed Signal","domain":"Legal & Investigative","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic;behavioral","modality":"text;voice;video","confidenceThreshold":"0.80","description":"Interviewee signals completion: That is everything; extended pause; repeated summary."},
    {"id":"legal_sig_voluntary_cooperation","name":"Voluntary Cooperation Signal","domain":"Legal & Investigative","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.75","description":"Interviewee demonstrates voluntary cooperative engagement."},
]

LEGAL_EMOTIONAL_STATES = [
    {"id":"legal_emo_defensive_state","name":"Defensive State","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"medium-high","valence":"negative","description":"Interviewee exhibits defensive posture: denial, deflection, topic avoidance."},
    {"id":"legal_emo_trauma_fragmentation_risk","name":"Trauma Fragmentation Risk","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"high","valence":"negative","description":"Trauma-driven memory fragmentation. Contraindicates Change Temporal Order and Change Perspective."},
    {"id":"legal_emo_false_memory_risk","name":"False Memory Risk","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"low","valence":"neutral","description":"High suggestibility or confabulation tendency. Contraindicates Change Perspective."},
    {"id":"legal_emo_coercive_context","name":"Coercive Context","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"high","valence":"negative","description":"Custodial or coercive context. Right to Silence is mandatory."},
    {"id":"legal_emo_any_interview_context","name":"Any Interview Context (Reid Block)","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Covers ALL interview contexts — CONTRAINDICATED target for Reid absolute block."},
    {"id":"legal_emo_interview_completed","name":"Interview Completed","domain":"Legal & Investigative","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"All PEACE phases completed. Signals end of all active technique activation."},
]

LEGAL_PROTOCOLS = [
    {"id":"legal_proto_peace","name":"PEACE Investigative Interview Framework","domain":"Legal & Investigative","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"UK Home Office ethical investigative interview: Preparation, Engage/Explain, Account, Closure, Evaluation.","sourceIds":"PEACE2000; Williamson1993"},
    {"id":"legal_proto_cognitive_interview","name":"Cognitive Interview Protocol","domain":"Legal & Investigative","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"4-component memory retrieval: mental reinstatement, report everything, change temporal order, change perspective.","sourceIds":"Fisher1992; Geiselman1985"},
    {"id":"legal_proto_statement_analysis","name":"Scientific Content Analysis (SCAN)","domain":"Legal & Investigative","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Linguistic analysis of statements to identify deception, omission, or construction markers.","sourceIds":"Adams1996; Sapir2000"},
    {"id":"legal_proto_structured_interview","name":"Structured Professional Interview","domain":"Legal & Investigative","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Evidence-based structured interview approach combining PEACE with Cognitive Interview. UK police standard.","sourceIds":"PEACE2000; Fisher1992; HomeOffice2007"},
]

LEGAL_RELATIONSHIPS = [
    ("legal_001_free_narrative_invitation","PRECEDES","legal_007_contradiction_challenge",None),
    ("legal_001_free_narrative_invitation","REQUIRES","legal_013_rapport_through_transparency",None),
    ("legal_002_cognitive_interview","ENHANCES","legal_001_free_narrative_invitation",None),
    ("legal_003_mental_reinstatement","TRIGGERS","legal_sig_memory_retrieval",None),
    ("legal_010_minimal_encourager","TRIGGERS","legal_sig_continued_narrative",None),
    ("legal_013_rapport_through_transparency","CONTRADICTS","legal_contraindicated_reid",None),
    ("legal_014_non_accusatorial_statement","TRIGGERED_BY","legal_emo_defensive_state",None),
    ("legal_015_account_gap_exploration","FOLLOWS","legal_001_free_narrative_invitation",None),
    ("legal_005_change_temporal_order","CONTRAINDICATED_WHEN","legal_emo_trauma_fragmentation_risk",{"reason":"Reverse-order recall destabilises traumatised witnesses","severity":"HIGH"}),
    ("legal_006_change_perspective","CONTRAINDICATED_WHEN","legal_emo_false_memory_risk",{"reason":"Perspective suggestion can create pseudo-memories","severity":"HIGH"}),
    ("legal_012_right_to_silence","CONTRAINDICATED_WHEN","legal_emo_coercive_context",{"reason":"Omitting right to silence in coercive context is absolute violation","severity":"CRITICAL"}),
    ("legal_contraindicated_reid","CONTRAINDICATED_WHEN","legal_emo_any_interview_context",{"reason":"ABSOLUTE: false confession risk — Leo 2008, Kassin 2012","severity":"ABSOLUTE","crossDomain":True}),
]


# ─────────────────────────────────────────────────────────────
# CORPORATE / ENGINEERING DOMAIN
# ─────────────────────────────────────────────────────────────

CORPORATE_STYLES = [
    {"id":"corp_style_radical_candor","name":"Radical Candor","domain":"Corporate & Engineering","classLabel":"CommunicationStyle","reviewStatus":"source_checked","dimension1":"care_personally:HIGH","dimension2":"challenge_directly:HIGH","targetState":True,"description":"Feedback combining genuine personal care with direct challenge. The target state."},
    {"id":"corp_style_obnoxious_aggression","name":"Obnoxious Aggression","domain":"Corporate & Engineering","classLabel":"CommunicationStyle","reviewStatus":"source_checked","dimension1":"care_personally:LOW","dimension2":"challenge_directly:HIGH","targetState":False,"description":"Challenges directly but without care. Feedback is blunt or contemptuous.","detectionSignals":"contempt_marker; blaming_language"},
    {"id":"corp_style_ruinous_empathy","name":"Ruinous Empathy","domain":"Corporate & Engineering","classLabel":"CommunicationStyle","reviewStatus":"source_checked","dimension1":"care_personally:HIGH","dimension2":"challenge_directly:LOW","targetState":False,"description":"Cares personally but avoids direct challenge. Prevents growth.","detectionSignals":"avoidance_substantive_critique; excessive_hedging"},
    {"id":"corp_style_manipulative_insincerity","name":"Manipulative Insincerity","domain":"Corporate & Engineering","classLabel":"CommunicationStyle","reviewStatus":"source_checked","dimension1":"care_personally:LOW","dimension2":"challenge_directly:LOW","targetState":False,"description":"Neither cares nor challenges. Passive-aggressive patterns.","detectionSignals":"passive_aggressive_markers; indirect_critique"},
]

CORPORATE_TECHNIQUES = [
    {"id":"corp_001_sbi_situation","name":"SBI Situation","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"CCL_SBI; ScottRadicalCandor","description":"First step of SBI: state the specific observable situation without evaluation.","whenToUse":"Opening step of structured feedback delivery.","whenNotToUse":"Public setting; high emotional arousal.","steps":"State: In [specific situation]...","successSignals":"Recipient nods or confirms they recall the specific event."},
    {"id":"corp_002_sbi_behavior","name":"SBI Behavior","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"CCL_SBI; ScottRadicalCandor","description":"Second step of SBI: describe specific observable behavior without interpretation or personality labelling.","whenToUse":"Second step of feedback delivery.","whenNotToUse":"When behavior cannot be stated without interpretation.","steps":"State: you [specific observable action]","successSignals":"Recipient can verify the behavior occurred.","contraindications":"Must describe observable behavior only — never personality traits."},
    {"id":"corp_003_sbi_impact","name":"SBI Impact","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"CCL_SBI; ScottRadicalCandor","description":"Third step of SBI: describe specific impact on self, team, or work — not on character.","whenToUse":"Final step of SBI sequence.","steps":"State: and the impact was [effect on team/work/self].","successSignals":"Recipient understands why the behavior mattered."},
    {"id":"corp_004_radical_candor_delivery","name":"Radical Candor Delivery","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"ScottRadicalCandor2017","description":"Full Radical Candor feedback delivery: genuine personal investment plus specific direct challenge via SBI in private channel.","whenToUse":"Any performance feedback in corporate context.","whenNotToUse":"Public setting; care_personally baseline not established.","steps":"1) Private channel 2) Check safety 3) SBI 4) Listen 5) Agree next step."},
    {"id":"corp_005_private_channel_enforcement","name":"Private Channel Enforcement","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"lowest-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"ScottRadicalCandor2017","description":"Ensures critique is delivered in a private channel only. Praise may be public; critique must always be private.","whenToUse":"Any time critique is about to be delivered.","whenNotToUse":"Never skip this precondition.","steps":"Confirm channel is private before critique. If not, defer.","reviewNotes":"Only corporate technique with an environmental constraint, not emotional-state constraint."},
    {"id":"corp_006_immediate_feedback","name":"Immediate Feedback","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"ScottRadicalCandor2017; CCL_SBI","description":"Feedback delivered within 48-hour window while specific detail remains fresh.","whenToUse":"As soon as private setting and calm available after observed behavior.","whenNotToUse":"High emotional arousal; public setting.","steps":"After observing behavior: wait for calm; find private channel; deliver within 48h."},
    {"id":"corp_007_direct_report_feedback","name":"Direct Report Feedback","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"ScottRadicalCandor2017","description":"Structured feedback from manager to direct report using full SBI with care-personally framing.","whenToUse":"Regular 1:1 sessions; post-incident review.","whenNotToUse":"No established relationship; public setting.","steps":"1) Care-personally signal 2) SBI 3) Invite response 4) Co-create action step."},
    {"id":"corp_008_upward_feedback","name":"Upward Feedback","domain":"Corporate & Engineering","tier":"Tier 2","cognitiveLoadProfile":"high-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Edmondson1999PsychSafety; ScottRadicalCandor2017","description":"Feedback from report to manager requiring confirmed psychological safety and SBI structure.","whenToUse":"Manager behavior has observable team impact and safety conditions are met.","whenNotToUse":"Psychological safety not confirmed; punitive culture."},
    {"id":"corp_009_nvc_observation","name":"NVC Observation","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Rosenberg2003NVC","description":"First step of NVC: state specific observable fact, free from evaluation or interpretation.","whenToUse":"Opening step of NVC sequence.","steps":"State: When I see or hear [specific observable fact]...","contraindications":"Observation must be factual — not evaluative."},
    {"id":"corp_010_nvc_feeling","name":"NVC Feeling","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Rosenberg2003NVC","description":"Second step of NVC: name the feeling using emotion vocabulary, not interpretations.","whenToUse":"NVC sequence; after observation stated.","steps":"State: I feel [emotion word]","contraindications":"Do not confuse feelings with thoughts: I feel that you is not a feeling."},
    {"id":"corp_011_nvc_need","name":"NVC Need","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Rosenberg2003NVC","description":"Third step of NVC: articulate underlying universal need, not a strategy.","whenToUse":"NVC sequence; after feeling stated.","steps":"State: because I need [universal need]","contraindications":"Need must be universal, not a strategy."},
    {"id":"corp_012_nvc_request","name":"NVC Request","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Rosenberg2003NVC","description":"Fourth step of NVC: specific, positive, genuinely refusable request.","whenToUse":"Final step of NVC; collaborative agreement-building.","steps":"State: would you be willing to [specific positive action]?","contraindications":"Must be specific, positive, and genuinely refusable."},
    {"id":"corp_016_winners_triangle_vulnerable","name":"Winner's Triangle: Vulnerable","domain":"Corporate & Engineering","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Choy1990WinnersTriangle; Karpman1968","description":"Moves Karpman Victim role to adaptive Vulnerable: acknowledges real feelings without helplessness.","whenToUse":"Drama triangle victim pattern detected.","steps":"Acknowledge real difficulty; separate feelings from helplessness; ask: What is one thing within your control here?","contraindications":"Do not use when person is genuine victim of abuse."},
    {"id":"corp_017_winners_triangle_assertive","name":"Winner's Triangle: Assertive","domain":"Corporate & Engineering","tier":"Tier 2","cognitiveLoadProfile":"high-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Choy1990WinnersTriangle; Karpman1968","description":"Moves Karpman Persecutor role to adaptive Assertive: direct and clear without blame or contempt.","whenToUse":"Drama triangle persecutor pattern detected.","steps":"Name behavior; state impact; make specific request without blame or contempt.","contraindications":"Requires calm emotional baseline."},
    {"id":"corp_018_winners_triangle_caring","name":"Winner's Triangle: Caring","domain":"Corporate & Engineering","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Choy1990WinnersTriangle; Karpman1968","description":"Moves Karpman Rescuer role to adaptive Caring: genuine support that empowers agency.","whenToUse":"Drama triangle rescuer pattern; over-helping dynamic.","steps":"Ask: What would be most helpful right now? Coach rather than rescue.","contraindications":"Do not rescue; caring means empowering, not solving."},
    {"id":"corp_019_psychological_safety_check","name":"Psychological Safety Check","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Edmondson1999PsychSafety; ScottRadicalCandor2017","description":"Pre-feedback gate assessing whether context has sufficient psychological safety for direct challenge.","whenToUse":"Before any substantive feedback; before upward feedback.","steps":"Assess: Can people disagree openly? Do errors get punished? Build safety before feedback if unsure."},
    {"id":"corp_020_context_setting_feedback","name":"Context Setting for Feedback","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"ScottRadicalCandor2017","description":"Brief framing statement before SBI establishing developmental intent and care-personally signal.","whenToUse":"Any spontaneous feedback delivery; when intent might be misread.","steps":"Say: I want to share something because I think it will help. Is now a good time?"},
    {"id":"corp_024_criticism_vs_complaint","name":"Criticism vs Complaint Distinction","domain":"Corporate & Engineering","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Gottman1994WhyMarriages; ScottRadicalCandor2017","description":"Meta-technique: check whether feedback is criticism (character attack) or complaint (specific behavior). Only complaints are deliverable.","whenToUse":"Before any feedback delivery; internal pre-flight check.","steps":"Test: Remove the behavior — does feedback still claim who the person IS? If yes, rewrite as observable behavior."},
    {"id":"corp_025_360_feedback_framing","name":"360-Degree Feedback Framing","domain":"Corporate & Engineering","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Bracken1997_360","description":"Frames feedback as collected from multiple perspectives to reduce single-source attribution.","whenToUse":"Formal review cycles; multi-source data available.","steps":"Say: I gathered input from several people. The pattern I am seeing is..."},
]

CORPORATE_SIGNAL_MARKERS = [
    {"id":"corp_sig_karpman_victim","name":"Karpman Victim Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.65","description":"Helplessness, learned powerlessness, persistent external blame without problem-solving."},
    {"id":"corp_sig_karpman_persecutor","name":"Karpman Persecutor Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.65","description":"Blaming, criticising, contemptuous patterns with power asymmetry."},
    {"id":"corp_sig_karpman_rescuer","name":"Karpman Rescuer Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral","modality":"text;voice;video","confidenceThreshold":"0.60","description":"Consistently takes over others problems, enables dependency."},
    {"id":"corp_sig_contempt_marker","name":"Contempt Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;prosodic","modality":"voice;video","confidenceThreshold":"0.80","description":"Contempt: eye-roll, dismissive tone, mocking. Gottman highest-severity marker."},
    {"id":"corp_sig_defensiveness","name":"Defensiveness Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.70","description":"Counter-attack, excuse-making, victim stance in response to feedback."},
    {"id":"corp_sig_stonewalling","name":"Stonewalling Detection","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.75","description":"Monosyllabic responses, withdrawal, refusal to engage."},
    {"id":"corp_sig_excessive_hedging","name":"Excessive Hedging","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.60","description":"Feedback so qualified the substantive message is obscured. Indicator of Ruinous Empathy."},
    {"id":"corp_sig_passive_aggressive","name":"Passive-Aggressive Marker","domain":"Corporate & Engineering","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice;video","confidenceThreshold":"0.55","description":"Sarcasm, indirect resistance, agreed-but-not-followed-through. Indicator of Manipulative Insincerity."},
]

CORPORATE_EMOTIONAL_STATES = [
    {"id":"corp_emo_psychological_safety","name":"Psychological Safety Confirmed","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Context where interpersonal risk-taking is demonstrably safe."},
    {"id":"corp_emo_high_arousal","name":"High Emotional Arousal","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"high","valence":"negative","description":"Either party in high arousal. Contraindicates immediate feedback."},
    {"id":"corp_emo_public_setting","name":"Public Setting (Critique Block)","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Critique would be in view of others. CONTRAINDICATED for all critique techniques."},
    {"id":"corp_emo_personality_attack_risk","name":"Personality Attack Risk","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Feedback framing has drifted from behavior to character."},
    {"id":"corp_emo_accountability","name":"Accountability State","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Recipient understands impact of their behavior and is open to change."},
    {"id":"corp_emo_calm_baseline","name":"Calm Baseline","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"low","valence":"neutral","description":"Both parties in regulated state. Prerequisite for assertive Winner Triangle."},
    {"id":"corp_emo_intervention_required","name":"Intervention Required","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"high","valence":"negative","description":"Contempt has reached severity requiring HR intervention."},
    {"id":"corp_emo_repair_required","name":"Repair Required","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Stonewalling occurred. Repair sequence required before communication resumes."},
    {"id":"corp_emo_further_challenge_active","name":"Further Challenge Active (Stonewalling Block)","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Stonewalling is active; further challenge CONTRAINDICATED."},
    {"id":"corp_emo_demand","name":"Demand (NVC Block)","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Request is non-negotiable; refusal not genuinely acceptable. CONTRADICTS NVC Request."},
    {"id":"corp_emo_interpretation_as_fact","name":"Interpretation as Fact","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Speaker states interpretation of intent as factual observation. CONTRADICTS NVC Observation."},
    {"id":"corp_emo_rescuer_enabling","name":"Rescuer Enabling","domain":"Corporate & Engineering","classLabel":"EmotionalState","reviewStatus":"source_checked","description":"Solving others problem reinforces dependency. CONTRADICTS Winner Triangle Caring."},
]

CORPORATE_PROTOCOLS = [
    {"id":"corp_proto_sbi","name":"SBI Feedback Protocol","domain":"Corporate & Engineering","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CCL Situation-Behavior-Impact: 3-step structured feedback ensuring behavioral specificity.","sourceIds":"CCL_SBI"},
    {"id":"corp_proto_nvc","name":"Nonviolent Communication Protocol","domain":"Corporate & Engineering","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Rosenberg NVC 4-component protocol: Observation, Feeling, Need, Request.","sourceIds":"Rosenberg2003NVC"},
    {"id":"corp_proto_radical_candor","name":"Radical Candor Protocol","domain":"Corporate & Engineering","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Kim Scott 4-quadrant model: Care Personally x Challenge Directly. Target: top-right quadrant.","sourceIds":"ScottRadicalCandor2017"},
]

CORPORATE_RELATIONSHIPS = [
    ("corp_001_sbi_situation","PRECEDES","corp_002_sbi_behavior",None),
    ("corp_002_sbi_behavior","PRECEDES","corp_003_sbi_impact",None),
    ("corp_009_nvc_observation","PRECEDES","corp_010_nvc_feeling",None),
    ("corp_010_nvc_feeling","PRECEDES","corp_011_nvc_need",None),
    ("corp_011_nvc_need","PRECEDES","corp_012_nvc_request",None),
    ("corp_020_context_setting_feedback","PRECEDES","corp_001_sbi_situation",None),
    ("corp_004_radical_candor_delivery","REQUIRES","corp_019_psychological_safety_check",None),
    ("corp_002_sbi_behavior","CONTRAINDICATED_WHEN","corp_emo_personality_attack_risk",{"reason":"Behavior step blocked when framing contains personality attribution","severity":"HIGH"}),
    ("corp_005_private_channel_enforcement","CONTRAINDICATED_WHEN","corp_emo_public_setting",{"reason":"Critique in public destroys psychological safety","severity":"CRITICAL"}),
    ("corp_006_immediate_feedback","CONTRAINDICATED_WHEN","corp_emo_high_arousal",{"reason":"Immediate feedback during arousal degrades reception","severity":"HIGH"}),
    ("corp_009_nvc_observation","CONTRADICTS","corp_emo_interpretation_as_fact",None),
    ("corp_012_nvc_request","CONTRADICTS","corp_emo_demand",None),
    ("corp_018_winners_triangle_caring","CONTRADICTS","corp_emo_rescuer_enabling",None),
    ("corp_003_sbi_impact","ENHANCES","corp_emo_accountability",None),
    ("corp_007_direct_report_feedback","ENHANCES","corp_emo_psychological_safety",None),
    ("corp_sig_karpman_victim","TRIGGERS","corp_016_winners_triangle_vulnerable",None),
    ("corp_sig_karpman_persecutor","TRIGGERS","corp_017_winners_triangle_assertive",None),
    ("corp_sig_karpman_rescuer","TRIGGERS","corp_018_winners_triangle_caring",None),
    ("corp_sig_contempt_marker","ESCALATES_TO","corp_emo_intervention_required",None),
    ("corp_sig_stonewalling","TRIGGERS","corp_emo_repair_required",None),
    ("corp_016_winners_triangle_vulnerable","RESOLVES","corp_sig_karpman_victim",None),
    ("corp_017_winners_triangle_assertive","RESOLVES","corp_sig_karpman_persecutor",None),
    ("corp_018_winners_triangle_caring","RESOLVES","corp_sig_karpman_rescuer",None),
]


# ─────────────────────────────────────────────────────────────
# EDUCATION DOMAIN
# ─────────────────────────────────────────────────────────────

EDUCATION_KNOWLEDGE_STATES = [
    {"id":"edu_ks_novice","name":"BKT: Novice State","domain":"Education","classLabel":"KnowledgeState","reviewStatus":"source_checked","p_know_range":"0.0-0.2","triggeredAct":"direct_instruction","description":"No or minimal prior knowledge. Triggers Direct Instruction."},
    {"id":"edu_ks_partial","name":"BKT: Partial Knowledge","domain":"Education","classLabel":"KnowledgeState","reviewStatus":"source_checked","p_know_range":"0.2-0.5","triggeredAct":"scaffolded_hint","description":"Partial knowledge; can engage but needs support. Triggers Scaffold."},
    {"id":"edu_ks_near_competent","name":"BKT: Near-Competent State","domain":"Education","classLabel":"KnowledgeState","reviewStatus":"source_checked","p_know_range":"0.3-0.75","triggeredAct":"socratic_question","description":"Developing knowledge; productive struggle possible. Triggers Socratic."},
    {"id":"edu_ks_mastered","name":"BKT: Mastered State","domain":"Education","classLabel":"KnowledgeState","reviewStatus":"source_checked","p_know_range":"> 0.85","p_learn":0.3,"p_guess":0.25,"p_slip":0.1,"p_forget":0.05,"triggeredAct":"transfer_probe; spaced_rep_schedule","description":"Demonstrated mastery in original context. Triggers Transfer Probe."},
    {"id":"edu_ks_transfer_confirmed","name":"BKT: Transfer Confirmed","domain":"Education","classLabel":"KnowledgeState","reviewStatus":"source_checked","p_know_range":"> 0.90","triggeredAct":"spaced_rep_schedule_extended","description":"Transfer to novel context confirmed. Final state."},
]

EDUCATION_TECHNIQUES = [
    {"id":"edu_001_socratic_opening","name":"Socratic Opening Question","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Collins1989CognitiveTutoring","bktTrigger":"p_know >= 0.3","description":"Open question to surface student current understanding before deeper engagement.","whenToUse":"Student has partial knowledge (BKT p_know 0.3-0.75).","whenNotToUse":"p_know < 0.3; no baseline.","steps":"Ask: What do you already know about [concept]?"},
    {"id":"edu_002_socratic_probe","name":"Socratic Probe","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Collins1989CognitiveTutoring; Graesser1995tutordialogue","bktTrigger":"partial_answer_signal","description":"Follow-up question probing assumptions and reasoning chains in a partial answer.","whenToUse":"Student has produced partial answer with retrievable reasoning.","whenNotToUse":"Student in confusion spiral; scaffold first.","steps":"Ask: Why do you think that? What evidence supports that?"},
    {"id":"edu_003_socratic_challenge","name":"Socratic Challenge","domain":"Education","tier":"Tier 2","cognitiveLoadProfile":"high-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"VanLehn2011tutoring","bktTrigger":"confident_wrong_answer AND p_know > 0.5","description":"Counter-example that destabilises a confidently held misconception.","whenToUse":"High-confidence misconception needing productive destabilisation.","whenNotToUse":"Student already low confidence.","steps":"Introduce counter-case: What would you say about [counter-example]? Does your answer still hold?","contraindications":"Contraindicated when student is in low-confidence state."},
    {"id":"edu_004_scaffolded_hint_t1","name":"Scaffolded Hint Tier 1","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Wood1976Scaffolding; VanLehn2011tutoring","bktTrigger":"confusion_signal AND p_know > 0.2","description":"Lightest scaffolding: reactivates prerequisite knowledge without revealing solution path.","whenToUse":"Student stuck but has prerequisite knowledge.","whenNotToUse":"p_know < 0.2; use Direct Instruction.","steps":"Ask: What do you know about [prerequisite]?"},
    {"id":"edu_005_scaffolded_hint_t2","name":"Scaffolded Hint Tier 2","domain":"Education","tier":"Tier 2","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Wood1976Scaffolding","bktTrigger":"tier1_hint_failed","description":"Heavier scaffolding: reveals solution approach without the final answer.","whenToUse":"After Tier 1 fails.","steps":"Say: The approach is to [method]. Try applying that."},
    {"id":"edu_006_scaffolded_hint_t3","name":"Scaffolded Hint Tier 3","domain":"Education","tier":"Tier 3","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Wood1976Scaffolding","bktTrigger":"tier2_hint_failed","description":"Near-complete scaffolding: reveals almost all answer structure, leaves final inference.","whenToUse":"After Tier 2 fails.","steps":"Say: You need [near-complete structure]; what goes in the last part?"},
    {"id":"edu_007_direct_instruction","name":"Direct Instruction","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Rosenshine1987DirectInstruction","bktTrigger":"p_know < 0.3 OR tier3_hint_failed","description":"Agent explicitly teaches concept when prerequisite gap prevents self-discovery.","whenToUse":"BKT p_know < 0.3; all scaffold tiers exhausted.","whenNotToUse":"Near-competent state; productive struggle possible.","steps":"State: [Concept] means [definition]. Key things: [1, 2, 3]."},
    {"id":"edu_008_worked_example","name":"Worked Example","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Sweller1988CognitiveLoad","bktTrigger":"after_direct_instruction OR example_requested","description":"Agent demonstrates technique application step-by-step before student applies independently.","whenToUse":"After direct instruction; student requests show me how.","whenNotToUse":"Near-mastery state; modelling reduces productive challenge.","steps":"Walk through: Here is how to apply [concept]: [steps]. Now you try."},
    {"id":"edu_010_spaced_rep_prompt","name":"Spaced Repetition Prompt","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Ebbinghaus1885; Cepeda2006SpacedPractice; Corbett1994BKT","bktTrigger":"p_know > 0.85 AND time_since_last > p_forget_threshold","description":"Retrieval practice prompt for previously mastered concept at optimum interval.","whenToUse":"BKT mastery confirmed AND time exceeds decay threshold.","whenNotToUse":"Concept not yet mastered.","steps":"Say: Let us revisit something you learned. [Concept]. What does it involve?"},
    {"id":"edu_011_error_correction","name":"Error Correction","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"low-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"VanLehn2011tutoring","bktTrigger":"wrong_answer AND p_slip_high","description":"Specific targeted correction identifying exact wrong element, explaining why, redirecting to correct understanding.","whenToUse":"Any wrong answer, misconception, or slip detected.","steps":"[Element] is not quite right because [reason]. The correct understanding is [correction].","contraindications":"Never shame-correct. Error correction must be specific, behavioral, non-punitive."},
    {"id":"edu_012_transfer_probe","name":"Transfer Probe","domain":"Education","tier":"Tier 2","cognitiveLoadProfile":"medium-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Haskell2001Transfer","bktTrigger":"p_know > 0.85 AND mastery_claim","description":"Tests whether mastered knowledge transfers to a novel context.","whenToUse":"After mastery in original context.","whenNotToUse":"Mastery not established.","steps":"Say: Now, in a different situation — [novel context] — how would you apply [concept]?"},
    {"id":"edu_013_praise_for_effort","name":"Praise for Effort","domain":"Education","tier":"Tier 1","cognitiveLoadProfile":"lowest-load","reviewStatus":"source_checked","classLabel":"CommunicationTechnique","sourceIds":"Dweck2006Mindset; Mueller1998PraiseMotivation","bktTrigger":"effort_signal; persistence_after_difficulty","description":"Specific praise targeting effort, strategy, or persistence — not outcome or innate ability.","whenToUse":"Effort, strategy, or persistence is visible.","whenNotToUse":"Praising ability not effort — rephrase first.","steps":"Say: I can see you worked hard to figure that out.","contraindications":"Do not praise ability. Praise effort, strategy, and persistence only."},
]

EDUCATION_SIGNAL_MARKERS = [
    {"id":"edu_sig_confusion","name":"Confusion Signal","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic;behavioral","modality":"text;voice","confidenceThreshold":"0.70","description":"Contradictory statements; question reversal; fragmented response; long silence after prompt."},
    {"id":"edu_sig_partial_answer","name":"Partial Answer","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.75","description":"Answer has correct elements but is incomplete or lacks full reasoning chain."},
    {"id":"edu_sig_confident_wrong_answer","name":"Confident Wrong Answer","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic;prosodic","modality":"text;voice","confidenceThreshold":"0.72","description":"Wrong answer with high apparent confidence; no hedging; may push back if questioned."},
    {"id":"edu_sig_wrong_answer","name":"Wrong Answer","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic","modality":"text;voice","confidenceThreshold":"0.85","description":"Factually incorrect answer; neutral or low confidence level."},
    {"id":"edu_sig_memory_decay","name":"Memory Decay Signal","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"temporal","modality":"system","confidenceThreshold":"1.0","description":"Time since last recall of mastered concept exceeds BKT p_forget threshold."},
    {"id":"edu_sig_effort_signal","name":"Effort Signal","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"behavioral;linguistic","modality":"text;voice","confidenceThreshold":"0.65","description":"Multiple attempts; self-correction; extended engagement; persisting after failure."},
    {"id":"edu_sig_cognitive_load","name":"High Cognitive Load","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"linguistic;behavioral","modality":"text;voice","confidenceThreshold":"0.65","description":"Multiple simultaneous errors; extremely brief responses; explicit overwhelm."},
    {"id":"edu_sig_prerequisite_gap","name":"Prerequisite Gap","domain":"Education","classLabel":"SignalMarker","reviewStatus":"source_checked","detectionMethod":"system;linguistic","modality":"system","confidenceThreshold":"0.80","description":"Student cannot engage with current concept; prerequisite concept p_know < 0.3."},
]

EDUCATION_EMOTIONAL_STATES = [
    {"id":"edu_emo_low_confidence","name":"Low Confidence","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"low","valence":"negative","description":"Hesitant, self-deprecating, reluctant to attempt. CONTRAINDICATED target for Socratic Challenge."},
    {"id":"edu_emo_shame_response","name":"Shame Response","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"high","valence":"negative","description":"Student experiencing shame about error or gap. CONTRADICTED by Error Correction."},
    {"id":"edu_emo_comprehension","name":"Comprehension State","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"medium","valence":"positive","description":"Active comprehension: engaged, following, building mental model."},
    {"id":"edu_emo_flow_state","name":"Flow State","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"medium","valence":"positive","description":"Optimal challenge-skill balance, intrinsic engagement. Minimize interruptions."},
    {"id":"edu_emo_frustration","name":"Frustration State","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"medium-high","valence":"negative","description":"Frustration from extended unsuccessful struggle. Triggers scaffold increase."},
    {"id":"edu_emo_disengagement","name":"Disengagement","domain":"Education","classLabel":"EmotionalState","reviewStatus":"source_checked","arousalLevel":"low","valence":"negative","description":"Minimal responses; off-topic; no attempt at prompts. Requires rapport repair."},
]

EDUCATION_PROTOCOLS = [
    {"id":"edu_coachidl_direct_instruction","name":"CoachIDL: Direct Instruction Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: agent explicitly teaches concept. Triggered when p_know < 0.3.","bktTrigger":"p_know < 0.3"},
    {"id":"edu_coachidl_socratic_question","name":"CoachIDL: Socratic Question Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: poses question to elicit reasoning. Triggered when 0.3 <= p_know <= 0.75.","bktTrigger":"0.3 <= p_know <= 0.75"},
    {"id":"edu_coachidl_scaffolded_hint","name":"CoachIDL: Scaffolded Hint Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: provides partial information. Triggered when confusion AND p_know > 0.2.","bktTrigger":"confusion_signal AND p_know > 0.2"},
    {"id":"edu_coachidl_spaced_rep","name":"CoachIDL: Spaced Repetition Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: prompts recall. Triggered when p_know > 0.85 AND time > decay threshold.","bktTrigger":"p_know > 0.85 AND time_since_last > decay_threshold"},
    {"id":"edu_coachidl_error_correction","name":"CoachIDL: Error Correction Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: corrects misconception. Triggered when wrong answer AND p_slip > 0.3.","bktTrigger":"wrong_answer AND p_slip > 0.3"},
    {"id":"edu_coachidl_worked_example","name":"CoachIDL: Worked Example Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: demonstrates technique. Triggered when example requested OR conceptual gap.","bktTrigger":"example_requested OR post_instruction_gap"},
    {"id":"edu_coachidl_transfer_probe","name":"CoachIDL: Transfer Probe Act","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"CoachIDL act: tests novel-context application. Triggered when p_know > 0.85.","bktTrigger":"p_know > 0.85 AND mastery_asserted"},
    {"id":"edu_proto_prerequisite_routing","name":"Prerequisite Routing Protocol","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Routes to prerequisite concept when current target has unmet prerequisite p_know < 0.3.","bktTrigger":"prerequisite_gap_detected","sourceIds":"Corbett1994BKT; VanLehn2011tutoring"},
    {"id":"edu_proto_bkt_update","name":"BKT Update Protocol","domain":"Education","classLabel":"DomainProtocol","reviewStatus":"source_checked","description":"Post-turn update of BKT KnowledgeState estimates using Bayesian update rule.","bktTrigger":"after_each_student_turn","sourceIds":"Corbett1994BKT"},
]

EDUCATION_RELATIONSHIPS = [
    ("edu_001_socratic_opening","PRECEDES","edu_002_socratic_probe",None),
    ("edu_004_scaffolded_hint_t1","PRECEDES","edu_005_scaffolded_hint_t2",None),
    ("edu_005_scaffolded_hint_t2","PRECEDES","edu_006_scaffolded_hint_t3",None),
    ("edu_006_scaffolded_hint_t3","PRECEDES","edu_007_direct_instruction",None),
    ("edu_007_direct_instruction","PRECEDES","edu_008_worked_example",None),
    ("edu_ks_near_competent","TRIGGERS","edu_001_socratic_opening",None),
    ("edu_ks_mastered","TRIGGERS","edu_012_transfer_probe",None),
    ("edu_ks_mastered","TRIGGERS","edu_010_spaced_rep_prompt",None),
    ("edu_sig_confusion","TRIGGERS","edu_004_scaffolded_hint_t1",None),
    ("edu_sig_partial_answer","TRIGGERS","edu_002_socratic_probe",None),
    ("edu_sig_confident_wrong_answer","TRIGGERS","edu_003_socratic_challenge",None),
    ("edu_sig_wrong_answer","TRIGGERS","edu_011_error_correction",None),
    ("edu_sig_memory_decay","TRIGGERS","edu_010_spaced_rep_prompt",None),
    ("edu_sig_effort_signal","TRIGGERS","edu_013_praise_for_effort",None),
    ("edu_sig_prerequisite_gap","TRIGGERS","edu_007_direct_instruction",None),
    ("edu_003_socratic_challenge","CONTRAINDICATED_WHEN","edu_emo_low_confidence",{"reason":"Challenge only high-confidence wrong answers; challenges low-confidence causes shutdown","severity":"HIGH"}),
    ("edu_011_error_correction","CONTRADICTS","edu_emo_shame_response",None),
    ("edu_008_worked_example","ENHANCES","edu_emo_comprehension",None),
    ("edu_010_spaced_rep_prompt","REQUIRES","edu_ks_mastered",None),
]


# ─────────────────────────────────────────────────────────────
# Main loader
# ─────────────────────────────────────────────────────────────

def run_one(stmt: dict) -> bool:
    """Run a single statement; return True on success, False on error."""
    body = {"statements": [stmt]}
    try:
        r = requests.post(NEO4J_HTTP, json=body, headers=HEADERS, timeout=60)
        r.raise_for_status()
        data = r.json()
        errs = data.get("errors", [])
        if errs:
            # Silently skip uniqueness violations — node already exists
            for e in errs:
                code = e.get("code", "")
                if "ConstraintValidationFailed" in code or "AlreadyExists" in code:
                    return True  # idempotent — treat as OK
            return False
        return True
    except Exception:
        return False


def load_domain(name: str, statements: list):
    print(f"\n  Loading {name}...", end=" ", flush=True)
    t0 = time.time()
    ok = errors = 0
    for stmt in statements:
        if run_one(stmt):
            ok += 1
        else:
            errors += 1
    elapsed = time.time() - t0
    color = "\033[32m" if errors == 0 else "\033[33m"
    status = "OK" if errors == 0 else f"WARN ({errors} errors)"
    print(f"{color}{status}\033[0m ({ok}/{len(statements)} statements, {elapsed:.1f}s)")


def main():
    print("=" * 62)
    print("  UCKB Phase 8 — Domain Node Loader (parameterized)")
    print("=" * 62)

    try:
        baseline = run([{"statement": "MATCH (n) RETURN COUNT(n) AS total"}])[0]["data"][0]["row"][0]
        print(f"\nConnected. Current nodes: {baseline}")
    except Exception as e:
        print(f"\nCannot connect to Neo4j: {e}")
        sys.exit(1)

    # ── Legal domain ─────────────────────────────────────────
    legal_stmts = (
        [merge_technique(t) for t in LEGAL_TECHNIQUES] +
        [merge_statement_marker(sm) for sm in LEGAL_STATEMENT_MARKERS] +
        [merge_signal_marker(sm) for sm in LEGAL_SIGNAL_MARKERS] +
        [merge_emotional_state(e) for e in LEGAL_EMOTIONAL_STATES] +
        [merge_domain_protocol(p) for p in LEGAL_PROTOCOLS] +
        [add_relationship(*r) for r in LEGAL_RELATIONSHIPS]
    )
    load_domain("Legal & Investigative", legal_stmts)

    # ── Corporate domain ─────────────────────────────────────
    corp_stmts = (
        [merge_comm_style(cs) for cs in CORPORATE_STYLES] +
        [merge_technique(t) for t in CORPORATE_TECHNIQUES] +
        [merge_signal_marker(sm) for sm in CORPORATE_SIGNAL_MARKERS] +
        [merge_emotional_state(e) for e in CORPORATE_EMOTIONAL_STATES] +
        [merge_domain_protocol(p) for p in CORPORATE_PROTOCOLS] +
        [add_relationship(*r) for r in CORPORATE_RELATIONSHIPS]
    )
    load_domain("Corporate & Engineering", corp_stmts)

    # ── Education domain ─────────────────────────────────────
    edu_stmts = (
        [merge_knowledge_state(ks) for ks in EDUCATION_KNOWLEDGE_STATES] +
        [merge_technique(t) for t in EDUCATION_TECHNIQUES] +
        [merge_signal_marker(sm) for sm in EDUCATION_SIGNAL_MARKERS] +
        [merge_emotional_state(e) for e in EDUCATION_EMOTIONAL_STATES] +
        [merge_domain_protocol(p) for p in EDUCATION_PROTOCOLS] +
        [add_relationship(*r) for r in EDUCATION_RELATIONSHIPS]
    )
    load_domain("Education", edu_stmts)

    # ── Final counts ─────────────────────────────────────────
    final = run([{"statement": "MATCH (n) RETURN COUNT(n) AS total"}])[0]["data"][0]["row"][0]
    print(f"\n{'=' * 62}")
    print(f"  Baseline: {baseline}  →  Final: {final}  (+{final-baseline} nodes)")
    print(f"{'=' * 62}")

    # Domain distribution
    rows = run([{"statement": """
        MATCH (n)
        WHERE n.domain IN ['Legal & Investigative','Corporate & Engineering','Education']
        RETURN n.domain AS domain, labels(n)[0] AS type, COUNT(n) AS cnt
        ORDER BY domain, type
    """}])[0]["data"]
    current = None
    for row in rows:
        domain, lbl, cnt = row["row"]
        if domain != current:
            current = domain
            print(f"\n  [{domain}]")
        print(f"    {lbl:<28} {cnt:>4}")

    print(f"\n  Open http://localhost:7474 — neo4j / uckb_admin_2024")


if __name__ == "__main__":
    main()
