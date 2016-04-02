package mammuthus.server.nginx.sdk

import java.lang.reflect.Proxy
import java.util.concurrent.ConcurrentHashMap

import mammuthus.controller.master.api.proxy.RestClientProxy
import net.csdn.common.settings.{ImmutableSettings, Settings}
import net.csdn.modules.threadpool.DefaultThreadPoolService
import net.csdn.modules.transport.{DefaultHttpTransportService, HttpTransportService}

/**
 * 9/7/15 WilliamZhu(allwefantasy@gmail.com)
 */
object NginxRestClient {
  private final val settings: Settings = ImmutableSettings.settingsBuilder().loadFromClasspath("application.yml").build()
  private final val transportService: HttpTransportService = new DefaultHttpTransportService(new DefaultThreadPoolService(settings), settings)

  private final val clients = new ConcurrentHashMap[String, NginxClientService]()


  def instance(host: String, port: Int): NginxClientService = {
    synchronized {
      val target = s"$host:$port"
      if (clients.containsKey(target)) {
        return clients.get(target)
      }
      val restClientProxy = new RestClientProxy(transportService)
      restClientProxy.target("http://" + host + ":" + port + "/")
      val item = Proxy.newProxyInstance(classOf[NginxRestClient].getClassLoader, Array(classOf[NginxClientService]), restClientProxy).asInstanceOf[NginxClientService]
      clients.put(target, item)
      item
    }
  }
}

class NginxRestClient
