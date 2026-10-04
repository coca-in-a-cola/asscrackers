# Local compatibility patch (v4.1.0)

`dialogue_manager.gd`, `get_line`: duplicate the compiled line dictionary before
adding runtime fields. Upstream assigns `data.resource = resource` to a dictionary
owned by that same resource, creating a strong reference cycle for every visited
line. Native startup testing reproduced 14 retained references after one intro.

The one-line copy prevents the cycle and keeps authored/imported resources
immutable during traversal. Public API and dialogue syntax are unchanged.
`tools/install_dialogue_manager.py` applies this exact patch when installing.
Re-check against upstream before upgrading. All other addon files are upstream.
