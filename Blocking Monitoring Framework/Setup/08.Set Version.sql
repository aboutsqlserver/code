/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*						     Set Version Number                             */
/****************************************************************************/

use DBA
go

exec dbo.SetVersion @Product = 'bmframework', @Version = '1.0.0';
