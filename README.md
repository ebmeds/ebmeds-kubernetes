## How to run locally
To get it running for testing the following tools are required:
- [Kube-controller to communication with the Kubernetes cluster](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Minikube to run a single-node Kubernetes cluster in a virtual machine](https://kubernetes.io/docs/tasks/tools/install-minikube/)
  - We recommend `KVM` for the Linux user and `HyperKit` for Mac user
  - See: https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver
  - Also, recommended setting Minikube memory to 8 gigabytes before starting it.
    - Command: `minikube config set memory 8196`
- [Terraform to run the EBMEDS infrastructure as code](https://learn.hashicorp.com/terraform/getting-started/install.html#installing-terraform)
- Require Docker authentication configuration file: `~/.docker/config.json` to pull EBMEDS images from Quay.
  - This should already exist but if it's missing just login to Quay registry.

```bash
# Start Minikube followingly from repo root:
$ minikube start --extra-config=apiserver.service-node-port-range=80-10000

# To spin up ebmeds
$ terraform apply
$ kubectl apply -f module/elastic/static/elastic.yml

# To check api-gateway status
$ curl $(minikube ip):3001/status
```

This repository is meant to provide a bare minimum deployment example of EBMEDS on Kubernetes. Integrators should adapt these instructions to their environments and specific needs. Container architecture should not be changed. Other modifications can be done as needed. Things to consider when deploying EBMEDS on Kubernetes:

- Use an ingress to suit your needs
- Load-balancing highly recommended
    - A single EBMEDS instance should not receive more than 5 RPS
- Auto-scaling highly recommended
- Play around with Kubernetes liveness-probes to avoid unnecessary killing of containers in case of high load
    - *periodSeconds* and *failureThreshold*

For further information and instructions on installing EBMEDS, please visit our online documentation at: https://ebmeds.github.io/docs/
The online documentation site is currently under construction.

## Index Lifecycle Management
This operation was carried out in Elastic stack version 7.6.0 – current release at the time.

EBMEDS sends request payloads, triggered reminders and logs data into specific Elasticsearch indices. These indices are:
- ebmeds-request-%{YYYY.MM}
- ebmeds-reminders-%{YYYY.MM}
- ebmeds-logs-%{YYYY.MM}

The year and month are dynamically formed to the index name, so for example, `ebmeds-request-2020.03` is one possible name and so on. To control these indices in `testing` and `staging` environments, we need to apply Elasticsearch index lifecycle manager, which set the rotate rules for every index.

In the Elasticsearch and for time series indices, the index lifecycle has four stages, and they are:
- Hot: the index is actively being updated and queried.
- Warm: the index is no longer being updated, but is still being queried.
- Cold: the index is no longer being updated and is seldom queried. The information still needs to be searchable, but it is okay if those queries are slower.
- Delete: the index is no longer needed and can safely be deleted.

#### Use in testing environment
For the `testing` environment, we get along just with three phases – hot, warm and delete. All the EBMEDS indices are time series. A new entry to the index enters the `hot` stage. After 30 days it will be moved to the `warm` stage and eventually deleted when the data age reached 90 days. Long story short: data that reside in the index longer than 90 days will be deleted.

The index lifecycle management policy needs to be first created into the Elasticsearch before it can be used in the Logstash else an exception is raised. The `ebmeds-policy` can be added into the Elasticsearch followingly:

```bash
curl -X PUT "http://localhost:9200/_ilm/policy/ebmeds-index-policy?pretty" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
      "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "30d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "0ms",
        "actions": {
          "allocate": {
            "number_of_replicas": 1,
            "include": {},
            "exclude": {},
            "require": {}
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "delete": {
        "min_age": "60d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
'
```

#### Advice for staging and production environment
This index lifecycle policy cannot be used in the `staging` and `production` without modification. The snapshot lifecycle must be configured for the `staging` and `production` environments before we can proceed any further. Make sure that the snapshot lifecycle is working correctly before proceeding. 

Also, make sure that everything is tested in `staging` environment and verified that they work correctly before applying index and snapshot lifecycle to the `production`.

Setting up the snapshot repository is required. Here is a simple skeleton snapshot policy of how to take snapshot daily at midnight.

```json
{
  "schedule": "0 0 * * * ?",
  "name": "ebmeds-snapshot-{now/d}",
  "repository": "<remember to configure repository>",
  "config": {
    "indices": ["*"]
  }
}
```
For more information about snapshot, please consult the links below.  Let say we name this snapshot lifecycle as `ebmeds-snapshot-policy`.

When the snapshot policy is created and running on the indices, we can proceed to set lifecycle policy for the EBMEDS indices. Following is a recommended policy to use with the EBMEDS, but further modification is required depending on the regulations.

```bash
curl -X PUT "http://localhost:9200/_ilm/policy/ebmeds-index-policy?pretty" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
      "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "30d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "0ms",
        "actions": {
          "allocate": {
            "number_of_replicas": 1,
            "include": {},
            "exclude": {},
            "require": {}
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "delete": {
        "min_age": "150d",
        "actions": {
	  "wait_for_snapshot" : {
            "policy": "ebmeds-snapshot-policy"
          }
          "delete": {}
        }
      }
    }
  }
}
'
```
We now set the `delete` stage to wait for the snapshot to be complete before we can proceed with deletion.

#### Further readings:
- [Manage the index lifecycle](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/index-lifecycle-management.html)
- [Snapshot and restore](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/snapshot-restore.html)
- [Manage the snapshot lifecycle](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/snapshot-lifecycle-management.html)
