package mammuthus.server.nginx


import net.csdn.ServiceFramwork
import net.csdn.bootstrap.Application


/**
 * 9/23/15 WilliamZhu(allwefantasy@gmail.com)
 */

object MammuthusNginx {
  def main(args: Array[String]) {
    ServiceFramwork.scanService.setLoader(classOf[MammuthusNginx])
    ServiceFramwork.disableDubbo()
    Application.main(args)
  }
}

class MammuthusNginx
