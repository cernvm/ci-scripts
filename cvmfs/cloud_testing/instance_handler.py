#!/bin/env python3

import time
import argparse
import sys
import os
import uuid

from keystoneauth1 import session
from keystoneauth1.identity import v3
from novaclient import client


def print_error(msg):
  print( "[Error]" , msg, file=sys.stderr)


def is_running(instance):
  return instance != None and instance.status == "ACTIVE"


def wait_for_instance(connection, instance_name, timeout = 900):
  start = time.time()
  counter = 0
  polling_interval = 15
  instance, = connection.servers.list(search_opts={'name': instance_name})
  while instance.status == "BUILD" and counter < timeout:
    instance, = connection.servers.list(search_opts={'name': instance_name})
    time.sleep(polling_interval)
    counter += polling_interval
  end = time.time()
  return end - start


def connect_to_openstack():

  application_credential = v3.ApplicationCredentialMethod(
              application_credential_secret=os.environ["OS_APPLICATION_CREDENTIAL_SECRET"],
              application_credential_id=os.environ["OS_APPLICATION_CREDENTIAL_ID"],
              )
  
  auth = v3.Auth(auth_url=os.environ["OS_AUTH_URL"],
                 auth_methods=[application_credential],
                )
  
  sess = session.Session(auth=auth)
  nova = client.Client(2, session=sess)
  return nova


def spawn_instance(connection, instance_name, image, key_name, flavor, userdata,  max_retries = 1):
  instance     = None
  time_backoff = 20
  retries      = 0
  meta = {'cern-waitdns': 'false', 'description': instance_name, 'cern-activedirectory': 'false', 'cern-checkdns': 'false'}
  flavor_id = connection.flavors.find(name=flavor)
  

  while not is_running(instance) and retries < max_retries:
    instance = connection.servers.create(name=instance_name, image=image,
            flavor=flavor_id, key_name=key_name, meta=meta)
    wait_for_instance(connection, instance_name)

    retries += 1
    if not is_running(instance):
      instance_id    = "unknown"
      instance_state = "unknown"
      if instance != None:
        instance_id    = str(instance.id)
        instance_state = str(instance.status)
        kill_instance(connection, instance_id)
      print_error("Failed spawning instance " + instance_id +
                  " (#: " + str(retries) + " | state: " + instance_state + ")")
      time.sleep(time_backoff)

  if not is_running(instance):
    return None
  return instance


def kill_instance(connection, instance_id):
  instance, = connection.servers.list(search_opts={'name': instance_id})
  instance.delete()
  return True


def create_instance(parent_parser, argv):
  parser = argparse.ArgumentParser(parents=[parent_parser])
  parser.add_argument("--instance-name",
                         nargs    = 1,
                         metavar  = "<instance_name>",
                         required = False,
                         dest     = "instance_name",
                         default  = "cvmtestserver",
                         help     = "name of the instance to boot")
  parser.add_argument("--image",
                         nargs    = 1,
                         metavar  = "<image_name>",
                         required = True,
                         dest     = "image",
                         help     = "Image identifier of the image to boot")
  parser.add_argument("--key",
                         nargs    = 1,
                         metavar  = "<key_name>",
                         required = False,
                         dest     = "key",
                         default  = "cvmfs-testing-v2",
                         help     = "Name of the access key to use")
  parser.add_argument("--instance-type",
                         nargs    = 1,
                         metavar  = "<instance_type>",
                         required = False,
                         dest     = "flavor",
                         default  = "m2.large",
                         help     = "VM flavor to use")
  parser.add_argument("--userdata",
                         nargs    = 1,
                         metavar  = "<user_data>",
                         required = False,
                         dest     = "userdata",
                         default  = "",
                         help     = "Cloud-init user data string")
  arguments = parser.parse_args(argv)

  image,      = arguments.image
  key_name   = arguments.key
  flavor     = arguments.flavor
  userdata   = arguments.userdata
  instance_name = arguments.instance_name
  random_suffix = str(uuid.uuid1())[:8]
  build_number = os.environ.get("BUILD_NUMBER", "")
  if build_number:
    instance_name = instance_name + "-jenkins" + str(build_number)
  instance_name = instance_name + "-" + random_suffix

  connection = connect_to_openstack()
  instance   = spawn_instance(connection, instance_name, image, key_name, flavor, userdata)
  wait_for_instance(connection, instance_name)

  instance, = connection.servers.list(search_opts={'name': instance_name})
  instance_ip4 = instance.addresses["CERN_NETWORK"][0]['addr']  

  
  if is_running(instance):
    print(instance_name , instance_ip4)
  else:
    print_error("Failed to start instance")
    exit(2)


def terminate_instance(parent_parser, argv):
  parser = argparse.ArgumentParser(parents=[parent_parser])
  parser.add_argument("--instance-id",
                         nargs    = 1,
                         metavar  = "<instance_id>",
                         required = True,
                         dest     = "instance_id",
                         help     = "Instance ID of the instance to terminate")
  arguments = parser.parse_args(argv)

  instance_id = arguments.instance_id[0]

  connection = connect_to_openstack()
  successful = kill_instance(connection, instance_id)

  if not successful:
    print_error("Failed to terminate instance")
    exit(2)


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#

parser = argparse.ArgumentParser(add_help    = False,
                                 description = "Start an Openstack instance")

if len(sys.argv) < 2:
    print_error("please provide 'spawn' or 'terminate' as a subcommand...")
    exit(1)

subcommand = sys.argv[1]
argv       = sys.argv[2:]
if   subcommand == "spawn":
  create_instance(parser, argv)
elif subcommand == "terminate":
  terminate_instance(parser, argv)
else:
  print_error("unrecognized subcommand '" + subcommand + "'")
  exit(1)
