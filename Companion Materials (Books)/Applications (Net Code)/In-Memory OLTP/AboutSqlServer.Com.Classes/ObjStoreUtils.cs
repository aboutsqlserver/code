/****************************************************************************/
/*                       Expert SQL Server In-Memory OLTP                   */
/*      APress. 2nd Edition. ISBN-13:978-1484227718  ISBN-10:1484227719     */
/*                                                                          */
/*          Written by Dmitri V. Korotkevitch & Vladimir Zatuliveter        */
/*                      http://aboutsqlserver.com                           */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                             Common Classes                               */
/****************************************************************************/
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading.Tasks;

namespace AboutSqlServer.Com.Classes
{
    public static class ObjStoreUtils
    {
        /// <summary>
        /// Serialize object of type T to the byte array
        /// </summary>
        public static byte[] Serialize<T>(T obj)
        {
            if (obj == null)
                return null; 
            using (var ms = new MemoryStream())
            {
                var formatter = new BinaryFormatter();
                formatter.Serialize(ms, obj);

                return ms.ToArray();
            }
        }

        /// <summary>
        /// Deserialize byte array to the object 
        /// </summary>
        public static T Deserialize<T>(byte[] data)
        {
            if (data == null || data.Length == 0)
                return default(T);
            using (var output = new MemoryStream(data))
            {
                var binForm = new BinaryFormatter();
                return (T)binForm.Deserialize(output);
            }
        }

        /* Those methods do not longer required in SQL Server 2016
        /// <summary>
        /// Split byte array to the multiple chunks
        /// </summary>
        public static List<byte[]> Split(byte[] data, int chunkSize)
        {
            var result = new List<byte[]>();

            for (int i = 0; i < data.Length; i += chunkSize)
            {
                int currentChunkSize = chunkSize;
                if (i + chunkSize > data.Length)
                    currentChunkSize = data.Length - i;

                var buffer = new byte[currentChunkSize];
                Array.Copy(data, i, buffer, 0, currentChunkSize);

                result.Add(buffer);
            }
            return result;
        }

        /// <summary>
        /// Combine multiple chunks into the byte array
        /// </summary>
        public static byte[] Merge(List<byte[]> arrays)
        {
            var rv = new byte[arrays.Sum(a => a.Length)];
            int offset = 0;
            foreach (byte[] array in arrays)
            {
                Buffer.BlockCopy(array, 0, rv, offset, array.Length);
                offset += array.Length;
            }
            return rv;
        } */
    }
}
