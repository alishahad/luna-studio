#!/usr/bin/env python2.7

###########################################################################
## Copyright (C) Flowbox, Inc / All Rights Reserved
## Unauthorized copying of this file, via any medium is strictly prohibited
## Proprietary and confidential
## Flowbox Team <contact@flowbox.io>, 2014
###########################################################################

import os.path
import os
import sys
import re
from utils.glob2 import glob
from utils.path import write_if_changed
from subprocess import call

header = '''\
---------------------------------------------------
-- This is a generated cabal configuration file. --
-- DO NOT EDIT!                                  --
-- Use gencabal instead.                         --
---------------------------------------------------

'''

def gencabal():
    tcabals_paths     = glob("**/*.tcabal")
    cabals_paths_orig = [dropext(path) for path in tcabals_paths]
    cabal_paths       = [path + '.cabal' for path in cabals_paths_orig]
    cabal_dirs        = [os.path.dirname(path) for path in cabal_paths]
    cabal_dirs        = ['.' if d == '' else d for d in cabal_dirs]

    tcabals = []
    for path in tcabals_paths:
        with open(path, 'r') as file:
            tcabals.append(file.read())

    cabals = [header + process(path, config) for (path, config) in zip(cabal_dirs, tcabals)]

    for (path, src) in zip(cabal_paths,cabals):
        write_if_changed(path, src)


def find_regex(basepath, regex=r'.*', exclude=r'_^'):
    files = []
    obj = re.compile(regex)
    obj_excl = re.compile(exclude)
    for path,_,filenames in os.walk(basepath):
        relpath = os.path.relpath(path,basepath)
        for filename in filenames:
            filerelpath = os.path.join(relpath,filename)
            filerelpath = filerelpath.replace(os.path.sep, '/') # srindows
            if filerelpath[:2] == './':
                filerelpath = filerelpath[2:]
            if obj.match(filerelpath) and not obj_excl.match(filerelpath):
                files.append(filerelpath)
    return files


indent = 4*' '


def dropext(path):
    out, _ = os.path.splitext(path)
    return out

def mkident(i):
    return i*indent

def fields(l):
    return '\n' + mkident(2) + (',\n' + mkident(2)).join(l)

def findmodules(basepath, regex=r'.*', exclude=r'_^'):
    paths        = find_regex(basepath, regex, exclude)
    # paths.sort()
    module_files = [dropext(path) for path in paths]
    modules      = sorted([name.replace('/','.') for name in module_files])

    return fields(modules)

def runcode(path, code):
    cwd = os.getcwd()
    os.chdir(path)
    out = eval(code)
    os.chdir(cwd)
    return out

def runmatch(path):
    def rundec(matchobj):
        code = matchobj.group(0)[1:-1]
        return runcode(path, code)
    return rundec

def process(path, config):
    match = re.compile(r'`[^`]*`')
    return match.sub(runmatch(path),config)
