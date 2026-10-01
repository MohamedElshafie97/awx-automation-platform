"""Print AWX instances as hostname:node_type:capacity (reads the API JSON on stdin)."""
import json
import sys

results = json.load(sys.stdin)["results"]
print(" ".join("%s:%s:%s" % (i["hostname"], i["node_type"], i["capacity"]) for i in results))
