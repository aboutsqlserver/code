/****************************************************************************/
/*                    Blocking Monitoring Framework                         */
/*                                                                          */
/*                  Written by Dmitri V. Korotkevitch                       */
/*                http://aboutsqlserver.com/bmframework                     */
/*                        dk@aboutsqlserver.com                             */
/****************************************************************************/
/*                              Initial Setup                               */
/*                            Setting Up Security                           */
/****************************************************************************/


-- Simple security setup can be done by enabling TRUSTWORTHY on DBA database.
-- Alternatively, you can set up cert-based security using script 05.2.Security(Certs).sql

use master
go

alter database DBA set trustworthy on
go
