package mammuthus.server.nginx.sdk

import net.csdn.common.settings.{Settings, ImmutableSettings}
import java.lang.reflect.Proxy
import net.csdn.modules.threadpool.DefaultThreadPoolService
import net.csdn.modules.transport.{HttpTransportService, DefaultHttpTransportService}
import mammuthus.controller.master.api.proxy.RestClientProxy
import java.util.concurrent.ConcurrentHashMap

/**
 * 9/7/15 WilliamZhu(allwefantasy@gmail.com)
 */
object NginxRestClient {
  private final val settings: Settings = ImmutableSettings.settingsBuilder().loadFromClasspath("application.yml").build()
  private final val transportService: HttpTransportService = new DefaultHttpTransportService(new DefaultThreadPoolService(settings), settings)
  private final val restClientProxy = new RestClientProxy(transportService)
  private final val clients = new ConcurrentHashMap[String, NginxClientService]()


  def instance(host: String, port: Int): NginxClientService = {
    synchronized {
      val target = s"$host:$port"
      if (clients.containsKey(target)) {
        return clients.get(target)
      }
      restClientProxy.target("http://" + host + ":" + port + "/")
      val item = Proxy.newProxyInstance(classOf[NginxRestClient].getClassLoader, Array(classOf[NginxClientService]), restClientProxy).asInstanceOf[NginxClientService]
      clients.put(target, item)
      item
    }
  }
}

class NginxRestClient
