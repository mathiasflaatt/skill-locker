### Ship

**You own what lands. Proof, review, PR, babysit, stop at the gate.**

The end state is **full-stop** (PR ready, unmerged) unless the user said "full send". Read the chosen skill and follow it: it holds the proof rules, the merge gate and when to ask. These steps are its order:

1. **Prove** every change on the real surface (full-send "Proof").
2. **Review** with **sol-loop** against the branch base. Fix real findings in one implementer subagent. Loop until Sol approves.
3. **PR** with **pr**, rebased on the default branch, ready for review (not draft). One line says how you proved it.
4. **Babysit** with **babysit-pr**: one `pr-wait` under Monitor, fix CI failures and real bot findings, prove each fix before you push, reply to dismissed findings with **leaving-pr-comments**.
5. **Gate.** full-stop: report ready / waiting for approval / blocked, PR open and unmerged. full-send: merge per its gate.

Stay active until step 5. Ending the turn while checks are pending stops the work.

**Reply:** PR link, head SHA, proof, Sol verdict, gate state, decisions made for the user.
