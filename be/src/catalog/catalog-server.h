// Copyright 2012 Cloudera Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef IMPALA_CATALOG_CATALOG_SERVER_H
#define IMPALA_CATALOG_CATALOG_SERVER_H

#include <string>
#include <vector>
#include <boost/shared_ptr.hpp>
#include <boost/thread/mutex.hpp>

#include "gen-cpp/CatalogService.h"
#include "gen-cpp/Frontend_types.h"
#include "gen-cpp/Types_types.h"
#include "catalog/catalog.h"
#include "statestore/state-store-subscriber.h"
#include "util/metrics.h"

namespace impala {

class StateStoreSubscriber;
class Catalog;
class TGetAllCatalogObjectsResponse;

// The Impala CatalogServer manages the caching and persistence of cluster-wide metadata.
// The CatalogServer aggregates the metadata from the Hive Metastore, the NameNode,
// and potentially additional sources in the future. The CatalogServer uses the
// StateStore to broadcast metadata updates across the cluster.
// The CatalogService directly handles executing metadata update requests
// (DDL requests) from clients via a Thrift interface.
// The CatalogServer has two main components - a C++ daemon that has the StateStore
// integration code, Thrift service implementiation, and exporting of the debug
// webpage/metrics.
// The other main component is written in Java and manages caching and updating of all
// metadata. For each StateStore heartbeat, the C++ Server queries the Java metadata
// cache over JNI to get the current state of the catalog. Any updates are broadcast to
// the rest of the cluster using the StateStore over the IMPALA_CATALOG_TOPIC.
// The CatalogServer must be the only writer to the IMPALA_CATALOG_TOPIC, meaning there
// cannot be multiple CatalogServers running at the same time, as the correctness of delta
// updates relies upon this assumption.
// TODO: In the future the CatalogServer could go into a "standby" mode if it detects
// updates from another writer on the topic. This is a bit tricky because it requires
// some basic form of leader election.
class CatalogServer {
 public:
  static std::string IMPALA_CATALOG_TOPIC;
  CatalogServer(Metrics* metrics);

  // Starts this CatalogService instance.
  // Returns OK unless some error occurred in which case the status is returned.
  Status Start();

  void RegisterWebpages(Webserver* webserver);

  // Returns the Thrift API interface that proxies requests onto the local CatalogService.
  const boost::shared_ptr<CatalogServiceIf>& thrift_iface() const {
    return thrift_iface_;
  }
  Catalog* catalog() const { return catalog_.get(); }

 private:
  // Thrift API implementation which proxies requests onto this CatalogService.
  boost::shared_ptr<CatalogServiceIf> thrift_iface_;
  Metrics* metrics_;
  boost::scoped_ptr<Catalog> catalog_;
  boost::scoped_ptr<StateStoreSubscriber> state_store_subscriber_;

  // Thread that polls the catalog for any updates.
  boost::scoped_ptr<Thread> catalog_update_gathering_thread_;

  // Tracks the set of catalog objects that exist via their topic entry key.
  // During each IMPALA_CATALOG_TOPIC heartbeat, stores the set of known catalog objects
  // that exist by their topic entry key. Used to track objects that have been removed
  // since the last heartbeat.
  std::set<std::string> catalog_object_topic_entry_keys_;

  // Protects catalog_update_cv_, catalog_objects_, catalog_objects_from_version_, and
  // last_sent_catalog_version.
  boost::mutex catalog_lock_;

  // Condition variable used to signal when the catalog_update_gathering_thread_ should
  // fetch its next set of updates from the JniCatalog. At the end of each statestore
  // heartbeat, this CV is signaled and the catalog_update_gathering_thread_ starts
  // querying the JniCatalog for catalog objects. Protected by the catalog_lock_.
  boost::condition_variable catalog_update_cv_;

  // The latest available set of catalog objects_. Set by the
  // catalog_update_gathering_thread_ and protected by the catalog_lock_.
  boost::scoped_ptr<TGetAllCatalogObjectsResponse> catalog_objects_;

  // Flag used to indicate when the catalog_objects_ are ready for processing by the
  // heartbeat thread. Set to false at the end of each heartbeat, before signaling
  // the catalog_update_gathering_thread_. Set to true by the
  // catalog_update_gathering_thread_ when it is done setting the latest
  // catalog_objects_.
  bool catalog_objects_ready_;

  // The last version of the catalog that was sent over a statestore heartbeat.
  // Set in UpdateCatalogTopicCallback() and protected by the catalog_lock_.
  int64_t last_sent_catalog_version_;

  // The lower bound of versions gathered by the catalog_update_gathering_thread_ and
  // protected by the catalog_lock_.
  int64_t catalog_objects_from_version_;

  // Called during each StateStore heartbeat and is responsible for updating the current
  // set of catalog objects in the IMPALA_CATALOG_TOPIC. Responds to each heartbeat with a
  // delta update containing the set of changes since the last heartbeat. This function
  // enumerates all catalog objects that were returned by the last call to the JniCatalog,
  // done via the catalog_update_gathering_thread_ thread. The topic is updated with any
  // catalog objects that are new or have been modified since the last heartbeat (by
  // comparing the catalog version of the object with the last_sent_catalog_version_
  // sent). Also determines any deletions of catalog objects by looking at the
  // difference of the last set of topic entry keys that were sent and the current set
  // of topic entry keys. At the end of execution it notifies the
  // catalog_update_gathering_thread_ to fetch the next set of updates from the
  // JniCatalog.
  // All updates are added to the subscriber_topic_updates list and sent back to the
  // StateStore.
  void UpdateCatalogTopicCallback(
      const StateStoreSubscriber::TopicDeltaMap& incoming_topic_deltas,
      std::vector<TTopicDelta>* subscriber_topic_updates);

  // Executed by the catalog_update_gathering_thread_. Calls into JniCatalog
  // to get the latest set of catalog objects that exist, along with some metadata on
  // each object. The results are stored in the shared catalog_objects_ data structure.
  void GatherCatalogUpdatesThread();

  void CatalogPathHandler(const Webserver::ArgumentMap& args,
      std::stringstream* output);

  // Debug webpage handler that is used to dump the internal state of catalog objects.
  // The caller specifies a "object_type" and "object_name" parameters and this function
  // will get the matching TCatalogObject struct, if one exists.
  // For example, to dump table "bar" in database "foo":
  // <host>:25020/catalog_objects?object_type=TABLE&object_name=foo.bar
  void CatalogObjectsPathHandler(const Webserver::ArgumentMap& args,
      std::stringstream* output);
};

}

#endif
