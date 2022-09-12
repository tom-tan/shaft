# Shaft: A workflow engine for CommandLineTool in local machine
[![release](https://badgen.net/github/release/tom-tan/shaft)](https://github.com/tom-tan/shaft/releases/latest)
[![license](https://badgen.net/github/license/tom-tan/shaft)](https://github.com/tom-tan/shaft/blob/main/LICENSE)
[![CI](https://github.com/tom-tan/shaft/actions/workflows/ci.yml/badge.svg)](https://github.com/tom-tan/shaft/actions/workflows/ci.yml)

Shaft is a workflow engine to be used as a "shaft" of other workflow engines for the [Common Workflow Language](https://www.commonwl.org/) (CWL).

The main purpose of this engine is to be embedded in more enhanced workflow engines such as [ep3](https://github.com/tom-tan/ep3) and therefore it focuses on supporting [CommandLineTool](https://www.commonwl.org/v1.2/CommandLineTool.html) and [ExpressionTool](https://www.commonwl.org/v1.2/Workflow.html#ExpressionTool) documents in local machines.

## Main features
- Easy to deploy (statically-linked binary)
- [Enable to take inherited process requirements and hints via input object](#passing-inherited-process-requirements-and-hints-via-input-object)
    - it is necessary to integrate shaft with other workflow engine that supports `Workflow`

## Conformance tests for CWL v1.0
[![release](https://badgen.net/github/release/tom-tan/shaft)](https://github.com/tom-tan/shaft/releases/latest) ![commit](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/commit.json)

### Classes
[![CommandLineTool](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/command_line_tool.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html) [![ExpressionTool](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/expression_tool.json?icon=commonwl)](https://www.commonwl.org/v1.0/Workflow.html#ExpressionTool)

### Required features
[![Required](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/required.json?icon=commonwl)](https://www.commonwl.org/v1.0/)

### Optional features
[![DockerRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/docker.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#DockerRequirement) [![EnvVarRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/env_var.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#EnvVarRequirement) [![InitialWorkDirRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/initial_work_dir.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#InitialWorkDirRequirement) [![InlineJavascriptRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/inline_javascript.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#InlineJavascriptRequirement) [![ResourceRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/resource.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#ResourceRequirement) [![SchemaDefRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/schema_def.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#SchemaDefRequirement) [![ShellCommandRequirement](https://badgen.net/https/raw.githubusercontent.com/tom-tan/conformance/master/shaft/cwl_v1.0/shaft_latest/shell_command.json?icon=commonwl)](https://www.commonwl.org/v1.0/CommandLineTool.html#ShellCommandRequirement)

## Shaft extension
### Taking inherited process requirements and hints via the input object

The [CWL specification](https://www.commonwl.org/v1.2/CommandLineTool.html#Requirements_and_hints) says that the step processes in a workflow must inherit requirements and hints declared in the parent workflow.

To integrate shaft with other workflow engine for `Workflow`, shaft can take inherited requirements and hints via `shaft:inherited-requirements` and `shaft:inherited-hints` in the input object. They must have an array of process requirements that are inherited from the parent workflow.

- Examples: Inheriting `EnvVarRequirement` via `shaft:inherited-requirements`
  - tests/tools/env-tool1-noenv.cwl
    ```cwl
    # based on https://github.com/common-workflow-language/common-workflow-language/blob/main/v1.0/v1.0/env-tool1.cwl
    class: CommandLineTool
    cwlVersion: v1.0
    hints:
      ResourceRequirement:
        ramMin: 8
    inputs:
      in: string
    outputs:
      out:
        type: File
        outputBinding:
          glob: out

    # requirements:
    #   EnvVarRequirement:
    #     envDef:
    #       TEST_ENV: $(inputs.in)

    baseCommand: ["/bin/sh", "-c", "echo $TEST_ENV"]

    stdout: out
    ```

  - test/jobs/senv-job.yml
    ```yml
    in: "hello test env"
    shaft:inherited-requirements:
      - class: EnvVarRequirement
        envDef:
          TEST_ENV: override
    ```
  - Execution result:
    ```console
    $ ./bin/shaft --quiet tests/tools/env-tool1-noenv.cwl tests/jobs/env-job.yml | jq .
    {
      "out": {
        "basename": "out",
        "checksum": "sha1$cdc1e84968261d6a7575b5305945471f8be199b6",
        "class": "File",
        "dirname": "/workspaces/shaft",
        "location": "file:///workspaces/shaft/out",
        "nameext": "",
        "nameroot": "out",
        "path": "/workspaces/shaft/out",
        "size": 9
      }
    }
    $ cat out
    override
    ```

- Examples: Inheriting `EnvVarRequirement` via `shaft:inherited-requirements` but not overriding requirements in the process
  - tests/tools/env-tool1.cwl
    ```cwl
    class: CommandLineTool
    cwlVersion: v1.0
    hints:
      ResourceRequirement:
        ramMin: 8
    inputs:
      in: string
    outputs:
      out:
        type: File
        outputBinding:
          glob: out

    requirements:
      EnvVarRequirement:
        envDef:
          TEST_ENV: $(inputs.in)

    baseCommand: ["/bin/sh", "-c", "echo $TEST_ENV"]

    stdout: out
    ```

  - test/jobs/senv-job.yml (same as previous example)
    ```yml
    in: "hello test env"
    shaft:inherited-requirements:
      - class: EnvVarRequirement
        envDef:
          TEST_ENV: override
    ```
  - Execution result:
    ```console
    $ ./bin/shaft --quiet tests/tools/env-tool1.cwl tests/jobs/env-job.yml | jq .
    {
      "out": {
        "basename": "out",
        "checksum": "sha1$b3ec4ed1749c207e52b3a6d08c59f31d83bff519",
        "class": "File",
        "dirname": "/workspaces/shaft",
        "location": "file:///workspaces/shaft/out",
        "nameext": "",
        "nameroot": "out",
        "path": "/workspaces/shaft/out",
        "size": 15
      }
    }
    $ cat out
    hello test env
    ```
