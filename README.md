kong-plugin-soap4kong
=====================

A plugin for the [Kong Microservice API Gateway](https://konghq.com/solutions/gateway/) to convert a REST API request to a SOAP request and convert the SOAP Response to json.

![soap4kong](images/soap4kong.png)

<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#compatible-kong-versions">Compatible Kong versions</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installation">Installation</a></li>
        <li><a href="#docker">Docker</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a>
      <ul>
        <li><a href="#configuration">Configuration</a></li>
        <li><a href="#enabling-plugin">Enabling plugin</a></li>
      </ul>
    </li>
    <li><a href="#development">Development</a>
      <ul>
        <li><a href="#preparing-the-development-environment">Preparing the development environment</a></li>
        <li><a href="#log-files">Log files</a></li>
        <li><a href="#testing">Testing</a></li>
      </ul>
    </li>
    <li><a href="#example">Example</a></li>
    <li><a href="https://github.com/adessoAG/kong-plugin-soap2rest/blob/master/LICENSE">License</a></li>
  </ol>
</details>

## Compatible Kong versions

| Kong Version |   Tests passing    |
| :----------- | :----------------: |
| 2.3.x        | :white_check_mark: |
| 2.2.x        | :white_check_mark: |
| 2.1.x        | :white_check_mark: |
| 2.0.x        | :white_check_mark: |

## Getting Started

### Installation

```bash
make install
```
