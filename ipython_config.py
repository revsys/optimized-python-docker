# pylint: disable=undefined-variable,missing-docstring

import os
HOME = os.environ['HOME']


VI_MODE = True if bool(os.environ.get('VIMODE', '')) else False

if VI_MODE:
    c.TerminalInteractiveShell.editing_mode = 'vi'

c.TerminalInteractiveShell.display_completions = 'readlinelike'
c.TerminalInteractiveShell.display_page = True
c.TerminalInteractiveShell.automagic = False
c.IPCompleter.merge_completions = False
c.IPCompleter.omit__names = 0
