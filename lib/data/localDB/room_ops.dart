import 'package:connects_you/data/localDB/db_ops.dart';
import 'package:connects_you/data/localDB/DDLs.dart';
import 'package:connects_you/data/models/room.dart';
import 'package:connects_you/constants/room_constants.dart';
import 'package:flutter/rendering.dart';

class RoomOpsDataSource {
  const RoomOpsDataSource._();

  static const _instance = RoomOpsDataSource._();

  factory RoomOpsDataSource() {
    return _instance;
  }

  Future<int> insertLocalRooms(List<Room> rooms) async {
    if (rooms.isNotEmpty) {
      final query = """INSERT OR IGNORE INTO ${TableNames.rooms} (
            ${RoomsTableColumns.roomId},
            ${RoomsTableColumns.roomName},
            ${RoomsTableColumns.roomLogoUrl},
            ${RoomsTableColumns.roomDescription},
            ${RoomsTableColumns.roomType},
            ${RoomsTableColumns.createdByUserId},
            ${RoomsTableColumns.createdAt},
            ${RoomsTableColumns.updatedAt}
          ) VALUES 
            ${rooms.map((room) => {
                RoomsTableColumns.roomId: room.roomId,
                RoomsTableColumns.roomName: room.roomName,
                RoomsTableColumns.roomLogoUrl: room.roomLogoUrl,
                RoomsTableColumns.roomDescription: room.roomDescription,
                RoomsTableColumns.roomType: room.roomType,
                RoomsTableColumns.createdByUserId: room.createdByUserId,
                RoomsTableColumns.createdAt: room.createdAt.toString(),
                RoomsTableColumns.updatedAt: room.updatedAt.toString(),
              })}""";
      final db = await DBOpsDataSource().getDB();
      final insertedRows = await db.rawInsert(query);
      debugPrint('rooms inserted $insertedRows');
      return insertedRows;
    }
    return 0;
  }

  Future<int> insertLocalRoomUsers(List<RoomUser> roomUsers) async {
    if (roomUsers.isNotEmpty) {
      final query = """INSERT OR IGNORE INTO ${TableNames.roomUsers} (
            ${RoomUsersTableColumns.roomId},
            ${RoomUsersTableColumns.userId},
            ${RoomUsersTableColumns.userRole},
            ${RoomUsersTableColumns.joinedAt}
          ) VALUES 
            ${roomUsers.map((roomUser) => {
                RoomUsersTableColumns.roomId: roomUser.roomId,
                RoomUsersTableColumns.userId: roomUser.userId,
                RoomUsersTableColumns.userRole: roomUser.userRole,
                RoomUsersTableColumns.joinedAt: roomUser.joinedAt.toString(),
              })}""";
      final db = await DBOpsDataSource().getDB();
      final insertedRows = await db.rawInsert(query);
      debugPrint('roomUsers inserted $insertedRows');
      return insertedRows;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> fetchLocalRoomUsers() async {
    final db = await DBOpsDataSource().getDB();
    return await db.query(TableNames.roomUsers);
  }

  Future<List<Map<String, dynamic>>> fetchLocalRoomACCUserId(
    String userId,
    String roomType,
  ) async {
    final query = """SELECT 
                       *
                      FROM
                        ${TableNames.rooms} 
                      WHERE
                        roomId = (
                          SELECT 
                            DISTINCT(roomId) 
                          FROM 
                            ${TableNames.roomUsers} 
                          WHERE 
                            userId = "$userId" 
                          AND 
                            userRole IN ${roomType == RoomType.DUET ? '("${RoomUserRole.DUET_CREATOR}", "${RoomUserRole.DUET_PARTICIPANT}")' : roomType == RoomType.GROUP ? '("${RoomUserRole.GROUP_ADMIN}", "${RoomUserRole.GROUP_MEMBER}")' : ''})""";
    final db = await DBOpsDataSource().getDB();
    return await db.rawQuery(query);
  }

  Future<List<Map<String, dynamic>>?> fetchLocalRoomUsersACCRoomId(
    String roomId,
    String roomType,
    String exceptedUserId,
  ) async {
    final query = """SELECT  
                       *
                      FROM 
                        ${TableNames.roomUsers}
                      WHERE
                        roomId = "$roomId" 
                      AND 
                        userRole IN ${roomType == RoomType.DUET ? '("${RoomUserRole.DUET_CREATOR}", "${RoomUserRole.DUET_PARTICIPANT}")' : roomType == RoomType.GROUP ? '("${RoomUserRole.GROUP_ADMIN}", "${RoomUserRole.GROUP_MEMBER}")' : ''} 
                      AND
                        userId != "$exceptedUserId"; """;
    final db = await DBOpsDataSource().getDB();
    return await db.rawQuery(query);
  }

  /// we are suppose to fetch last 25 (limit 25 desc) messages rooms and store in inside provider.
  /// and inside the chat room screen on reaching end, we fetch another 50 messages and store in inside provider/store
  Future<List<Map<String, dynamic>>> fetchInitialLocalRoomMessages() async {
    const query = """ WITH sorted_messages AS (
                        SELECT 
                          * 
                        FROM 
                          ${TableNames.messages} 
                        ORDER BY 
                          updatedAt DESC
                      )
                    SELECT 
                      r.*, 
                      (
                        SELECT 
                          JSON_GROUP_ARRAY(JSON(res))
                        FROM (
                          SELECT JSON_OBJECT(
                            '_id', _id,
                            'messageId', messageId,
                            'messageText', messageText,
                            'messageType', messageType,
                            'senderUserId', senderUserId,
                            'receiverUserId', receiverUserId,
                            'roomId', roomId,
                            'replyMessageId', replyMessageId,
                            'sendAt', sendAt,
                            'updatedAt', updatedAt,
                            'messageSeenInfo', messageSeenInfo,
                            'isSent', isSent,
                            'haveThreadId', haveThreadId,
                            'belongsToThreadId', belongsToThreadId
                          ) AS res
                            FROM 
                              sorted_messages 
                            WHERE
                              roomId = r.roomId
                            LIMIT 25
                        )
                      ) AS messages
                    FROM 
                      ${TableNames.rooms} r 
                  """;
    final db = await DBOpsDataSource().getDB();
    return await db.rawQuery(query);
  }
}