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

package com.cloudera.impala.catalog;

import java.util.HashMap;

import org.apache.hadoop.hive.metastore.api.StorageDescriptor;

import parquet.hive.DeprecatedParquetInputFormat;
import parquet.hive.DeprecatedParquetOutputFormat;
import parquet.hive.serde.ParquetHiveSerDe;

import com.cloudera.impala.thrift.THdfsFileFormat;
import com.google.common.base.Preconditions;

public class HiveStorageDescriptorFactory {
  /**
   * Creates and returns a Hive StoreDescriptor for the given FileFormat and RowFormat.
   * Currently supports creating StorageDescriptors for Parquet, Text, Sequence, and
   * RC file.
   * TODO: Add support for Avro and HBase
   */
  public static StorageDescriptor createSd(THdfsFileFormat fileFormat, RowFormat rowFormat) {
    Preconditions.checkNotNull(fileFormat);
    Preconditions.checkNotNull(rowFormat);

    StorageDescriptor sd = null;
    switch(fileFormat) {
      case PARQUET: sd = createParquetFileSd(); break;
      case RC_FILE: sd = createRcFileSd(); break;
      case SEQUENCE_FILE: sd = createSequenceFileSd(); break;
      case TEXT: sd = createTextSd(); break;
      case AVRO: sd = createAvroSd(); break;
      default: throw new UnsupportedOperationException(
          "Unsupported file format: " + fileFormat);
    }

    if (rowFormat.getFieldDelimiter() != null) {
      sd.getSerdeInfo().putToParameters(
          "serialization.format", rowFormat.getFieldDelimiter());
      sd.getSerdeInfo().putToParameters("field.delim", rowFormat.getFieldDelimiter());
    }
    if (rowFormat.getEscapeChar() != null) {
      sd.getSerdeInfo().putToParameters("escape.delim", rowFormat.getEscapeChar());
    }
    if (rowFormat.getLineDelimiter() != null) {
      sd.getSerdeInfo().putToParameters("line.delim", rowFormat.getLineDelimiter());
    }
    return sd;
  }

  private static StorageDescriptor createParquetFileSd() {
    StorageDescriptor sd = createGenericSd();
    sd.setInputFormat(DeprecatedParquetInputFormat.class.getName());
    sd.setOutputFormat(DeprecatedParquetOutputFormat.class.getName());
    sd.getSerdeInfo().setSerializationLib(ParquetHiveSerDe.class.getName());
    sd.setCompressed(false);
    return sd;
  }

  private static StorageDescriptor createTextSd() {
    StorageDescriptor sd = createGenericSd();
    sd.setInputFormat(org.apache.hadoop.mapred.TextInputFormat.class.getName());
    sd.setOutputFormat(
        org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat.class.getName());
    sd.getSerdeInfo().setSerializationLib(
        org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe.class.getName());
    sd.setCompressed(false);
    return sd;
  }

  private static StorageDescriptor createSequenceFileSd() {
    StorageDescriptor sd = createGenericSd();
    sd.setInputFormat(org.apache.hadoop.mapred.SequenceFileInputFormat.class.getName());
    sd.setOutputFormat(
        org.apache.hadoop.hive.ql.io.HiveSequenceFileOutputFormat.class.getName());
    sd.getSerdeInfo().setSerializationLib(
        org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe.class.getName());
    sd.setCompressed(false);
    return sd;
  }

  private static StorageDescriptor createRcFileSd() {
    StorageDescriptor sd = createGenericSd();
    sd.setInputFormat(org.apache.hadoop.hive.ql.io.RCFileInputFormat.class.getName());
    sd.setOutputFormat(org.apache.hadoop.hive.ql.io.RCFileOutputFormat.class.getName());
    sd.getSerdeInfo().setSerializationLib(
        org.apache.hadoop.hive.serde2.columnar.ColumnarSerDe.class.getName());
    sd.setCompressed(false);
    return sd;
  }

  private static StorageDescriptor createAvroSd() {
    StorageDescriptor sd = createGenericSd();
    sd.setInputFormat(
        org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat.class.getName());
    sd.setOutputFormat(
        org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat.class.getName());
    sd.getSerdeInfo().setSerializationLib(
        org.apache.hadoop.hive.serde2.avro.AvroSerDe.class.getName());
    // Writing compressed Avro tables is done using a session level configuration
    // setting, it is not specified as part of the table metadata. This compression
    // property has a different purpose.
    sd.setCompressed(false);
    return sd;
  }

  /**
   * Creates a new StorageDescriptor with options common to all storage formats.
   */
  private static StorageDescriptor createGenericSd() {
    StorageDescriptor sd = new StorageDescriptor();
    sd.setSerdeInfo(new org.apache.hadoop.hive.metastore.api.SerDeInfo());
    sd.getSerdeInfo().setParameters(new HashMap<String, String>());
    return sd;
  }
}
