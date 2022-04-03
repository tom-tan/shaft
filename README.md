# Shaft: A workflow engine for CommandLineTool in local machine
[![CI](https://github.com/tom-tan/shaft/actions/workflows/ci.yml/badge.svg)](https://github.com/tom-tan/shaft/actions/workflows/ci.yml)
[![license](https://badgen.net/github/license/tom-tan/shaft)](https://github.com/tom-tan/shaft/blob/main/LICENSE)

Shaft is a workflow engine for the [Common Workflow Language](https://www.commonwl.org/) (CWL).
It aims to be an internal component of other full featured workflow engines such as [ep3](https://github.com/tom-tan/ep3). Therefore it only supports [CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html) and [ExpressionTool](https://www.commonwl.org/v1.2/Workflow.html#ExpressionTool) definitions in local machines.

## Main features
- Easy to deploy (statically-linked binary)

## Conformance tests for CWL v1.0
[![release](https://badgen.net/github/release/tom-tan/shaft)](https://github.com/tom-tan/shaft/releases/latest) ![commit](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/commit.json)

### Classes
[![CommandLineTool](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/command_line_tool.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html) [![ExpressionTool](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/expression_tool.json?icon=commonwl)](https://www.commonwl.org/v1.0/Workflow.html#ExpressionTool)

### Required features
[![Required](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/required.json?icon=commonwl)](https://www.commonwl.org/v1.0/)

### Optional features
[![DockerRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/docker.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#DockerRequirement) [![EnvVarRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/env_var.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#EnvVarRequirement) [![InitialWorkDirRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/initial_work_dir.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#InitialWorkDirRequirement) [![InlineJavascriptRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/inline_javascript.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#InlineJavascriptRequirement) [![ResourceRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/resource.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#ResourceRequirement) [![SchemaDefRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/schema_def.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#SchemaDefRequirement) [![ShellCommandRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/shell_command.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#ShellCommandRequirement)
