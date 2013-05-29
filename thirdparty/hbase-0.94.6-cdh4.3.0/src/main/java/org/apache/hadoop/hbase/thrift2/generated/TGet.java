/**
 * Autogenerated by Thrift Compiler (0.9.0)
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */
package org.apache.hadoop.hbase.thrift2.generated;

import org.apache.thrift.scheme.IScheme;
import org.apache.thrift.scheme.SchemeFactory;
import org.apache.thrift.scheme.StandardScheme;

import org.apache.thrift.scheme.TupleScheme;
import org.apache.thrift.protocol.TTupleProtocol;
import org.apache.thrift.protocol.TProtocolException;
import org.apache.thrift.EncodingUtils;
import org.apache.thrift.TException;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.EnumMap;
import java.util.Set;
import java.util.HashSet;
import java.util.EnumSet;
import java.util.Collections;
import java.util.BitSet;
import java.nio.ByteBuffer;
import java.util.Arrays;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Used to perform Get operations on a single row.
 * 
 * The scope can be further narrowed down by specifying a list of
 * columns or column families.
 * 
 * To get everything for a row, instantiate a Get object with just the row to get.
 * To further define the scope of what to get you can add a timestamp or time range
 * with an optional maximum number of versions to return.
 * 
 * If you specify a time range and a timestamp the range is ignored.
 * Timestamps on TColumns are ignored.
 * 
 * TODO: Filter, Locks
 */
public class TGet implements org.apache.thrift.TBase<TGet, TGet._Fields>, java.io.Serializable, Cloneable {
  private static final org.apache.thrift.protocol.TStruct STRUCT_DESC = new org.apache.thrift.protocol.TStruct("TGet");

  private static final org.apache.thrift.protocol.TField ROW_FIELD_DESC = new org.apache.thrift.protocol.TField("row", org.apache.thrift.protocol.TType.STRING, (short)1);
  private static final org.apache.thrift.protocol.TField COLUMNS_FIELD_DESC = new org.apache.thrift.protocol.TField("columns", org.apache.thrift.protocol.TType.LIST, (short)2);
  private static final org.apache.thrift.protocol.TField TIMESTAMP_FIELD_DESC = new org.apache.thrift.protocol.TField("timestamp", org.apache.thrift.protocol.TType.I64, (short)3);
  private static final org.apache.thrift.protocol.TField TIME_RANGE_FIELD_DESC = new org.apache.thrift.protocol.TField("timeRange", org.apache.thrift.protocol.TType.STRUCT, (short)4);
  private static final org.apache.thrift.protocol.TField MAX_VERSIONS_FIELD_DESC = new org.apache.thrift.protocol.TField("maxVersions", org.apache.thrift.protocol.TType.I32, (short)5);

  private static final Map<Class<? extends IScheme>, SchemeFactory> schemes = new HashMap<Class<? extends IScheme>, SchemeFactory>();
  static {
    schemes.put(StandardScheme.class, new TGetStandardSchemeFactory());
    schemes.put(TupleScheme.class, new TGetTupleSchemeFactory());
  }

  public ByteBuffer row; // required
  public List<TColumn> columns; // optional
  public long timestamp; // optional
  public TTimeRange timeRange; // optional
  public int maxVersions; // optional

  /** The set of fields this struct contains, along with convenience methods for finding and manipulating them. */
  public enum _Fields implements org.apache.thrift.TFieldIdEnum {
    ROW((short)1, "row"),
    COLUMNS((short)2, "columns"),
    TIMESTAMP((short)3, "timestamp"),
    TIME_RANGE((short)4, "timeRange"),
    MAX_VERSIONS((short)5, "maxVersions");

    private static final Map<String, _Fields> byName = new HashMap<String, _Fields>();

    static {
      for (_Fields field : EnumSet.allOf(_Fields.class)) {
        byName.put(field.getFieldName(), field);
      }
    }

    /**
     * Find the _Fields constant that matches fieldId, or null if its not found.
     */
    public static _Fields findByThriftId(int fieldId) {
      switch(fieldId) {
        case 1: // ROW
          return ROW;
        case 2: // COLUMNS
          return COLUMNS;
        case 3: // TIMESTAMP
          return TIMESTAMP;
        case 4: // TIME_RANGE
          return TIME_RANGE;
        case 5: // MAX_VERSIONS
          return MAX_VERSIONS;
        default:
          return null;
      }
    }

    /**
     * Find the _Fields constant that matches fieldId, throwing an exception
     * if it is not found.
     */
    public static _Fields findByThriftIdOrThrow(int fieldId) {
      _Fields fields = findByThriftId(fieldId);
      if (fields == null) throw new IllegalArgumentException("Field " + fieldId + " doesn't exist!");
      return fields;
    }

    /**
     * Find the _Fields constant that matches name, or null if its not found.
     */
    public static _Fields findByName(String name) {
      return byName.get(name);
    }

    private final short _thriftId;
    private final String _fieldName;

    _Fields(short thriftId, String fieldName) {
      _thriftId = thriftId;
      _fieldName = fieldName;
    }

    public short getThriftFieldId() {
      return _thriftId;
    }

    public String getFieldName() {
      return _fieldName;
    }
  }

  // isset id assignments
  private static final int __TIMESTAMP_ISSET_ID = 0;
  private static final int __MAXVERSIONS_ISSET_ID = 1;
  private byte __isset_bitfield = 0;
  private _Fields optionals[] = {_Fields.COLUMNS,_Fields.TIMESTAMP,_Fields.TIME_RANGE,_Fields.MAX_VERSIONS};
  public static final Map<_Fields, org.apache.thrift.meta_data.FieldMetaData> metaDataMap;
  static {
    Map<_Fields, org.apache.thrift.meta_data.FieldMetaData> tmpMap = new EnumMap<_Fields, org.apache.thrift.meta_data.FieldMetaData>(_Fields.class);
    tmpMap.put(_Fields.ROW, new org.apache.thrift.meta_data.FieldMetaData("row", org.apache.thrift.TFieldRequirementType.REQUIRED, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.STRING        , true)));
    tmpMap.put(_Fields.COLUMNS, new org.apache.thrift.meta_data.FieldMetaData("columns", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.ListMetaData(org.apache.thrift.protocol.TType.LIST, 
            new org.apache.thrift.meta_data.StructMetaData(org.apache.thrift.protocol.TType.STRUCT, TColumn.class))));
    tmpMap.put(_Fields.TIMESTAMP, new org.apache.thrift.meta_data.FieldMetaData("timestamp", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.I64)));
    tmpMap.put(_Fields.TIME_RANGE, new org.apache.thrift.meta_data.FieldMetaData("timeRange", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.StructMetaData(org.apache.thrift.protocol.TType.STRUCT, TTimeRange.class)));
    tmpMap.put(_Fields.MAX_VERSIONS, new org.apache.thrift.meta_data.FieldMetaData("maxVersions", org.apache.thrift.TFieldRequirementType.OPTIONAL, 
        new org.apache.thrift.meta_data.FieldValueMetaData(org.apache.thrift.protocol.TType.I32)));
    metaDataMap = Collections.unmodifiableMap(tmpMap);
    org.apache.thrift.meta_data.FieldMetaData.addStructMetaDataMap(TGet.class, metaDataMap);
  }

  public TGet() {
  }

  public TGet(
    ByteBuffer row)
  {
    this();
    this.row = row;
  }

  /**
   * Performs a deep copy on <i>other</i>.
   */
  public TGet(TGet other) {
    __isset_bitfield = other.__isset_bitfield;
    if (other.isSetRow()) {
      this.row = org.apache.thrift.TBaseHelper.copyBinary(other.row);
;
    }
    if (other.isSetColumns()) {
      List<TColumn> __this__columns = new ArrayList<TColumn>();
      for (TColumn other_element : other.columns) {
        __this__columns.add(new TColumn(other_element));
      }
      this.columns = __this__columns;
    }
    this.timestamp = other.timestamp;
    if (other.isSetTimeRange()) {
      this.timeRange = new TTimeRange(other.timeRange);
    }
    this.maxVersions = other.maxVersions;
  }

  public TGet deepCopy() {
    return new TGet(this);
  }

  @Override
  public void clear() {
    this.row = null;
    this.columns = null;
    setTimestampIsSet(false);
    this.timestamp = 0;
    this.timeRange = null;
    setMaxVersionsIsSet(false);
    this.maxVersions = 0;
  }

  public byte[] getRow() {
    setRow(org.apache.thrift.TBaseHelper.rightSize(row));
    return row == null ? null : row.array();
  }

  public ByteBuffer bufferForRow() {
    return row;
  }

  public TGet setRow(byte[] row) {
    setRow(row == null ? (ByteBuffer)null : ByteBuffer.wrap(row));
    return this;
  }

  public TGet setRow(ByteBuffer row) {
    this.row = row;
    return this;
  }

  public void unsetRow() {
    this.row = null;
  }

  /** Returns true if field row is set (has been assigned a value) and false otherwise */
  public boolean isSetRow() {
    return this.row != null;
  }

  public void setRowIsSet(boolean value) {
    if (!value) {
      this.row = null;
    }
  }

  public int getColumnsSize() {
    return (this.columns == null) ? 0 : this.columns.size();
  }

  public java.util.Iterator<TColumn> getColumnsIterator() {
    return (this.columns == null) ? null : this.columns.iterator();
  }

  public void addToColumns(TColumn elem) {
    if (this.columns == null) {
      this.columns = new ArrayList<TColumn>();
    }
    this.columns.add(elem);
  }

  public List<TColumn> getColumns() {
    return this.columns;
  }

  public TGet setColumns(List<TColumn> columns) {
    this.columns = columns;
    return this;
  }

  public void unsetColumns() {
    this.columns = null;
  }

  /** Returns true if field columns is set (has been assigned a value) and false otherwise */
  public boolean isSetColumns() {
    return this.columns != null;
  }

  public void setColumnsIsSet(boolean value) {
    if (!value) {
      this.columns = null;
    }
  }

  public long getTimestamp() {
    return this.timestamp;
  }

  public TGet setTimestamp(long timestamp) {
    this.timestamp = timestamp;
    setTimestampIsSet(true);
    return this;
  }

  public void unsetTimestamp() {
    __isset_bitfield = EncodingUtils.clearBit(__isset_bitfield, __TIMESTAMP_ISSET_ID);
  }

  /** Returns true if field timestamp is set (has been assigned a value) and false otherwise */
  public boolean isSetTimestamp() {
    return EncodingUtils.testBit(__isset_bitfield, __TIMESTAMP_ISSET_ID);
  }

  public void setTimestampIsSet(boolean value) {
    __isset_bitfield = EncodingUtils.setBit(__isset_bitfield, __TIMESTAMP_ISSET_ID, value);
  }

  public TTimeRange getTimeRange() {
    return this.timeRange;
  }

  public TGet setTimeRange(TTimeRange timeRange) {
    this.timeRange = timeRange;
    return this;
  }

  public void unsetTimeRange() {
    this.timeRange = null;
  }

  /** Returns true if field timeRange is set (has been assigned a value) and false otherwise */
  public boolean isSetTimeRange() {
    return this.timeRange != null;
  }

  public void setTimeRangeIsSet(boolean value) {
    if (!value) {
      this.timeRange = null;
    }
  }

  public int getMaxVersions() {
    return this.maxVersions;
  }

  public TGet setMaxVersions(int maxVersions) {
    this.maxVersions = maxVersions;
    setMaxVersionsIsSet(true);
    return this;
  }

  public void unsetMaxVersions() {
    __isset_bitfield = EncodingUtils.clearBit(__isset_bitfield, __MAXVERSIONS_ISSET_ID);
  }

  /** Returns true if field maxVersions is set (has been assigned a value) and false otherwise */
  public boolean isSetMaxVersions() {
    return EncodingUtils.testBit(__isset_bitfield, __MAXVERSIONS_ISSET_ID);
  }

  public void setMaxVersionsIsSet(boolean value) {
    __isset_bitfield = EncodingUtils.setBit(__isset_bitfield, __MAXVERSIONS_ISSET_ID, value);
  }

  public void setFieldValue(_Fields field, Object value) {
    switch (field) {
    case ROW:
      if (value == null) {
        unsetRow();
      } else {
        setRow((ByteBuffer)value);
      }
      break;

    case COLUMNS:
      if (value == null) {
        unsetColumns();
      } else {
        setColumns((List<TColumn>)value);
      }
      break;

    case TIMESTAMP:
      if (value == null) {
        unsetTimestamp();
      } else {
        setTimestamp((Long)value);
      }
      break;

    case TIME_RANGE:
      if (value == null) {
        unsetTimeRange();
      } else {
        setTimeRange((TTimeRange)value);
      }
      break;

    case MAX_VERSIONS:
      if (value == null) {
        unsetMaxVersions();
      } else {
        setMaxVersions((Integer)value);
      }
      break;

    }
  }

  public Object getFieldValue(_Fields field) {
    switch (field) {
    case ROW:
      return getRow();

    case COLUMNS:
      return getColumns();

    case TIMESTAMP:
      return Long.valueOf(getTimestamp());

    case TIME_RANGE:
      return getTimeRange();

    case MAX_VERSIONS:
      return Integer.valueOf(getMaxVersions());

    }
    throw new IllegalStateException();
  }

  /** Returns true if field corresponding to fieldID is set (has been assigned a value) and false otherwise */
  public boolean isSet(_Fields field) {
    if (field == null) {
      throw new IllegalArgumentException();
    }

    switch (field) {
    case ROW:
      return isSetRow();
    case COLUMNS:
      return isSetColumns();
    case TIMESTAMP:
      return isSetTimestamp();
    case TIME_RANGE:
      return isSetTimeRange();
    case MAX_VERSIONS:
      return isSetMaxVersions();
    }
    throw new IllegalStateException();
  }

  @Override
  public boolean equals(Object that) {
    if (that == null)
      return false;
    if (that instanceof TGet)
      return this.equals((TGet)that);
    return false;
  }

  public boolean equals(TGet that) {
    if (that == null)
      return false;

    boolean this_present_row = true && this.isSetRow();
    boolean that_present_row = true && that.isSetRow();
    if (this_present_row || that_present_row) {
      if (!(this_present_row && that_present_row))
        return false;
      if (!this.row.equals(that.row))
        return false;
    }

    boolean this_present_columns = true && this.isSetColumns();
    boolean that_present_columns = true && that.isSetColumns();
    if (this_present_columns || that_present_columns) {
      if (!(this_present_columns && that_present_columns))
        return false;
      if (!this.columns.equals(that.columns))
        return false;
    }

    boolean this_present_timestamp = true && this.isSetTimestamp();
    boolean that_present_timestamp = true && that.isSetTimestamp();
    if (this_present_timestamp || that_present_timestamp) {
      if (!(this_present_timestamp && that_present_timestamp))
        return false;
      if (this.timestamp != that.timestamp)
        return false;
    }

    boolean this_present_timeRange = true && this.isSetTimeRange();
    boolean that_present_timeRange = true && that.isSetTimeRange();
    if (this_present_timeRange || that_present_timeRange) {
      if (!(this_present_timeRange && that_present_timeRange))
        return false;
      if (!this.timeRange.equals(that.timeRange))
        return false;
    }

    boolean this_present_maxVersions = true && this.isSetMaxVersions();
    boolean that_present_maxVersions = true && that.isSetMaxVersions();
    if (this_present_maxVersions || that_present_maxVersions) {
      if (!(this_present_maxVersions && that_present_maxVersions))
        return false;
      if (this.maxVersions != that.maxVersions)
        return false;
    }

    return true;
  }

  @Override
  public int hashCode() {
    return 0;
  }

  public int compareTo(TGet other) {
    if (!getClass().equals(other.getClass())) {
      return getClass().getName().compareTo(other.getClass().getName());
    }

    int lastComparison = 0;
    TGet typedOther = (TGet)other;

    lastComparison = Boolean.valueOf(isSetRow()).compareTo(typedOther.isSetRow());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetRow()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.row, typedOther.row);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetColumns()).compareTo(typedOther.isSetColumns());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetColumns()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.columns, typedOther.columns);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetTimestamp()).compareTo(typedOther.isSetTimestamp());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetTimestamp()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.timestamp, typedOther.timestamp);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetTimeRange()).compareTo(typedOther.isSetTimeRange());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetTimeRange()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.timeRange, typedOther.timeRange);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    lastComparison = Boolean.valueOf(isSetMaxVersions()).compareTo(typedOther.isSetMaxVersions());
    if (lastComparison != 0) {
      return lastComparison;
    }
    if (isSetMaxVersions()) {
      lastComparison = org.apache.thrift.TBaseHelper.compareTo(this.maxVersions, typedOther.maxVersions);
      if (lastComparison != 0) {
        return lastComparison;
      }
    }
    return 0;
  }

  public _Fields fieldForId(int fieldId) {
    return _Fields.findByThriftId(fieldId);
  }

  public void read(org.apache.thrift.protocol.TProtocol iprot) throws org.apache.thrift.TException {
    schemes.get(iprot.getScheme()).getScheme().read(iprot, this);
  }

  public void write(org.apache.thrift.protocol.TProtocol oprot) throws org.apache.thrift.TException {
    schemes.get(oprot.getScheme()).getScheme().write(oprot, this);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder("TGet(");
    boolean first = true;

    sb.append("row:");
    if (this.row == null) {
      sb.append("null");
    } else {
      org.apache.thrift.TBaseHelper.toString(this.row, sb);
    }
    first = false;
    if (isSetColumns()) {
      if (!first) sb.append(", ");
      sb.append("columns:");
      if (this.columns == null) {
        sb.append("null");
      } else {
        sb.append(this.columns);
      }
      first = false;
    }
    if (isSetTimestamp()) {
      if (!first) sb.append(", ");
      sb.append("timestamp:");
      sb.append(this.timestamp);
      first = false;
    }
    if (isSetTimeRange()) {
      if (!first) sb.append(", ");
      sb.append("timeRange:");
      if (this.timeRange == null) {
        sb.append("null");
      } else {
        sb.append(this.timeRange);
      }
      first = false;
    }
    if (isSetMaxVersions()) {
      if (!first) sb.append(", ");
      sb.append("maxVersions:");
      sb.append(this.maxVersions);
      first = false;
    }
    sb.append(")");
    return sb.toString();
  }

  public void validate() throws org.apache.thrift.TException {
    // check for required fields
    if (row == null) {
      throw new org.apache.thrift.protocol.TProtocolException("Required field 'row' was not present! Struct: " + toString());
    }
    // check for sub-struct validity
    if (timeRange != null) {
      timeRange.validate();
    }
  }

  private void writeObject(java.io.ObjectOutputStream out) throws java.io.IOException {
    try {
      write(new org.apache.thrift.protocol.TCompactProtocol(new org.apache.thrift.transport.TIOStreamTransport(out)));
    } catch (org.apache.thrift.TException te) {
      throw new java.io.IOException(te);
    }
  }

  private void readObject(java.io.ObjectInputStream in) throws java.io.IOException, ClassNotFoundException {
    try {
      // it doesn't seem like you should have to do this, but java serialization is wacky, and doesn't call the default constructor.
      __isset_bitfield = 0;
      read(new org.apache.thrift.protocol.TCompactProtocol(new org.apache.thrift.transport.TIOStreamTransport(in)));
    } catch (org.apache.thrift.TException te) {
      throw new java.io.IOException(te);
    }
  }

  private static class TGetStandardSchemeFactory implements SchemeFactory {
    public TGetStandardScheme getScheme() {
      return new TGetStandardScheme();
    }
  }

  private static class TGetStandardScheme extends StandardScheme<TGet> {

    public void read(org.apache.thrift.protocol.TProtocol iprot, TGet struct) throws org.apache.thrift.TException {
      org.apache.thrift.protocol.TField schemeField;
      iprot.readStructBegin();
      while (true)
      {
        schemeField = iprot.readFieldBegin();
        if (schemeField.type == org.apache.thrift.protocol.TType.STOP) { 
          break;
        }
        switch (schemeField.id) {
          case 1: // ROW
            if (schemeField.type == org.apache.thrift.protocol.TType.STRING) {
              struct.row = iprot.readBinary();
              struct.setRowIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 2: // COLUMNS
            if (schemeField.type == org.apache.thrift.protocol.TType.LIST) {
              {
                org.apache.thrift.protocol.TList _list8 = iprot.readListBegin();
                struct.columns = new ArrayList<TColumn>(_list8.size);
                for (int _i9 = 0; _i9 < _list8.size; ++_i9)
                {
                  TColumn _elem10; // required
                  _elem10 = new TColumn();
                  _elem10.read(iprot);
                  struct.columns.add(_elem10);
                }
                iprot.readListEnd();
              }
              struct.setColumnsIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 3: // TIMESTAMP
            if (schemeField.type == org.apache.thrift.protocol.TType.I64) {
              struct.timestamp = iprot.readI64();
              struct.setTimestampIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 4: // TIME_RANGE
            if (schemeField.type == org.apache.thrift.protocol.TType.STRUCT) {
              struct.timeRange = new TTimeRange();
              struct.timeRange.read(iprot);
              struct.setTimeRangeIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          case 5: // MAX_VERSIONS
            if (schemeField.type == org.apache.thrift.protocol.TType.I32) {
              struct.maxVersions = iprot.readI32();
              struct.setMaxVersionsIsSet(true);
            } else { 
              org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
            }
            break;
          default:
            org.apache.thrift.protocol.TProtocolUtil.skip(iprot, schemeField.type);
        }
        iprot.readFieldEnd();
      }
      iprot.readStructEnd();

      // check for required fields of primitive type, which can't be checked in the validate method
      struct.validate();
    }

    public void write(org.apache.thrift.protocol.TProtocol oprot, TGet struct) throws org.apache.thrift.TException {
      struct.validate();

      oprot.writeStructBegin(STRUCT_DESC);
      if (struct.row != null) {
        oprot.writeFieldBegin(ROW_FIELD_DESC);
        oprot.writeBinary(struct.row);
        oprot.writeFieldEnd();
      }
      if (struct.columns != null) {
        if (struct.isSetColumns()) {
          oprot.writeFieldBegin(COLUMNS_FIELD_DESC);
          {
            oprot.writeListBegin(new org.apache.thrift.protocol.TList(org.apache.thrift.protocol.TType.STRUCT, struct.columns.size()));
            for (TColumn _iter11 : struct.columns)
            {
              _iter11.write(oprot);
            }
            oprot.writeListEnd();
          }
          oprot.writeFieldEnd();
        }
      }
      if (struct.isSetTimestamp()) {
        oprot.writeFieldBegin(TIMESTAMP_FIELD_DESC);
        oprot.writeI64(struct.timestamp);
        oprot.writeFieldEnd();
      }
      if (struct.timeRange != null) {
        if (struct.isSetTimeRange()) {
          oprot.writeFieldBegin(TIME_RANGE_FIELD_DESC);
          struct.timeRange.write(oprot);
          oprot.writeFieldEnd();
        }
      }
      if (struct.isSetMaxVersions()) {
        oprot.writeFieldBegin(MAX_VERSIONS_FIELD_DESC);
        oprot.writeI32(struct.maxVersions);
        oprot.writeFieldEnd();
      }
      oprot.writeFieldStop();
      oprot.writeStructEnd();
    }

  }

  private static class TGetTupleSchemeFactory implements SchemeFactory {
    public TGetTupleScheme getScheme() {
      return new TGetTupleScheme();
    }
  }

  private static class TGetTupleScheme extends TupleScheme<TGet> {

    @Override
    public void write(org.apache.thrift.protocol.TProtocol prot, TGet struct) throws org.apache.thrift.TException {
      TTupleProtocol oprot = (TTupleProtocol) prot;
      oprot.writeBinary(struct.row);
      BitSet optionals = new BitSet();
      if (struct.isSetColumns()) {
        optionals.set(0);
      }
      if (struct.isSetTimestamp()) {
        optionals.set(1);
      }
      if (struct.isSetTimeRange()) {
        optionals.set(2);
      }
      if (struct.isSetMaxVersions()) {
        optionals.set(3);
      }
      oprot.writeBitSet(optionals, 4);
      if (struct.isSetColumns()) {
        {
          oprot.writeI32(struct.columns.size());
          for (TColumn _iter12 : struct.columns)
          {
            _iter12.write(oprot);
          }
        }
      }
      if (struct.isSetTimestamp()) {
        oprot.writeI64(struct.timestamp);
      }
      if (struct.isSetTimeRange()) {
        struct.timeRange.write(oprot);
      }
      if (struct.isSetMaxVersions()) {
        oprot.writeI32(struct.maxVersions);
      }
    }

    @Override
    public void read(org.apache.thrift.protocol.TProtocol prot, TGet struct) throws org.apache.thrift.TException {
      TTupleProtocol iprot = (TTupleProtocol) prot;
      struct.row = iprot.readBinary();
      struct.setRowIsSet(true);
      BitSet incoming = iprot.readBitSet(4);
      if (incoming.get(0)) {
        {
          org.apache.thrift.protocol.TList _list13 = new org.apache.thrift.protocol.TList(org.apache.thrift.protocol.TType.STRUCT, iprot.readI32());
          struct.columns = new ArrayList<TColumn>(_list13.size);
          for (int _i14 = 0; _i14 < _list13.size; ++_i14)
          {
            TColumn _elem15; // required
            _elem15 = new TColumn();
            _elem15.read(iprot);
            struct.columns.add(_elem15);
          }
        }
        struct.setColumnsIsSet(true);
      }
      if (incoming.get(1)) {
        struct.timestamp = iprot.readI64();
        struct.setTimestampIsSet(true);
      }
      if (incoming.get(2)) {
        struct.timeRange = new TTimeRange();
        struct.timeRange.read(iprot);
        struct.setTimeRangeIsSet(true);
      }
      if (incoming.get(3)) {
        struct.maxVersions = iprot.readI32();
        struct.setMaxVersionsIsSet(true);
      }
    }
  }

}
